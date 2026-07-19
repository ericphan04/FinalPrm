import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp, FieldValue } from 'firebase-admin/firestore';

admin.initializeApp();
const db = admin.firestore();

// 1. CREATE CHECKOUT CALLABLE
export const createCheckout = functions.https.onCall(async (data, context) => {
  const auth = context.auth;
  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Người dùng chưa đăng nhập');
  }
  const uid = auth.uid;
  const { items, address, paymentMethod, idempotencyKey } = data;
  if (!items || !Array.isArray(items) || items.length === 0 || !address || !paymentMethod || !idempotencyKey) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin đặt hàng bắt buộc');
  }

  // Idempotency check
  const idempotencyRef = db.collection('checkouts').doc(idempotencyKey);
  const idempotencySnap = await idempotencyRef.get();
  if (idempotencySnap.exists) {
    const checkoutData = idempotencySnap.data();
    return {
      checkoutId: idempotencySnap.id,
      orderIds: checkoutData?.orderIds || [],
      totalAmount: checkoutData?.totalVnd || 0,
    };
  }

  // Run transaction
  const result = await db.runTransaction(async (transaction) => {
    // Read all products and variants first
    const productRefs = items.map(item => db.collection('products').doc(item.productId));
    const productSnaps = [];
    for (const ref of productRefs) {
      productSnaps.push(await transaction.get(ref));
    }

    const variantRefs = items.map(item => db.collection('products').doc(item.productId).collection('variants').doc(item.variantId));
    const variantSnaps = [];
    for (const ref of variantRefs) {
      variantSnaps.push(await transaction.get(ref));
    }

    // Verify stock and price details
    const orderItemsBySeller = new Map<string, any[]>();
    let totalVnd = 0;

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const productSnap = productSnaps[i];
      const variantSnap = variantSnaps[i];

      if (!productSnap.exists) {
        throw new functions.https.HttpsError('not-found', `Không tìm thấy sản phẩm ${item.productId}`);
      }
      if (!variantSnap.exists) {
        throw new functions.https.HttpsError('not-found', `Không tìm thấy biến thể ${item.variantId}`);
      }

      const productData = productSnap.data()!;
      const variantData = variantSnap.data()!;

      if (productData.status !== 'published') {
        throw new functions.https.HttpsError('failed-precondition', `Sản phẩm ${productData.name} đang không được mở bán`);
      }

      const availableStock = variantData.stockQuantity ?? 0;
      if (availableStock < item.quantity) {
        throw new functions.https.HttpsError('resource-exhausted', `Sản phẩm ${productData.name} (${variantData.size}/${variantData.color}) đã hết hàng hoặc không đủ tồn kho`);
      }

      const basePrice = productData.basePrice ?? 0;
      const priceDifference = variantData.priceDifference ?? 0;
      const itemPrice = basePrice + priceDifference;

      // Group by seller
      const sellerId = productData.sellerId;

      if (!orderItemsBySeller.has(sellerId)) {
        orderItemsBySeller.set(sellerId, []);
      }

      const snapshotItem = {
        productId: item.productId,
        variantId: item.variantId,
        productName: productData.name,
        size: variantData.size,
        color: variantData.color,
        price: itemPrice,
        quantity: item.quantity,
        imageUrl: (productData.images && productData.images.length > 0) ? productData.images[0] : "",
      };

      orderItemsBySeller.get(sellerId)!.push(snapshotItem);
      totalVnd += itemPrice * item.quantity;

      // Update Stock
      transaction.update(variantRefs[i], {
        stockQuantity: availableStock - item.quantity
      });
    }

    // Create Checkout Doc ID
    const checkoutId = idempotencyKey;
    const orderIds: string[] = [];

    // Create Seller Orders
    for (const [sellerId, sellerItems] of orderItemsBySeller.entries()) {
      const orderId = db.collection('orders').doc().id;
      orderIds.push(orderId);

      const sellerSubtotal = sellerItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
      const storeId = items.length > 0 ? (productSnaps[0].data()?.storeId || sellerId) : sellerId;

      const orderData = {
        checkoutId,
        buyerId: uid,
        sellerId,
        storeId,
        status: 'pending',
        totals: {
          subtotal: sellerSubtotal,
          shipping: 0,
          total: sellerSubtotal
        },
        itemSnapshots: sellerItems,
        timeline: [
          {
            status: 'pending',
            note: 'Đơn hàng được khởi tạo thành công',
            createdAt: Timestamp.now()
          }
        ],
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        shippingAddress: address,
        paymentMethod
      };

      transaction.set(db.collection('orders').doc(orderId), orderData);
    }

    // Write Checkout Doc
    const checkoutDoc = {
      buyerId: uid,
      orderIds,
      totalVnd,
      addressSnapshot: address,
      idempotencyKey,
      createdAt: Timestamp.now()
    };
    transaction.set(idempotencyRef, checkoutDoc);

    // Delete Cart Items
    for (const item of items) {
      if (item.cartItemId) {
        transaction.delete(db.collection('users').doc(uid).collection('cart').doc(item.cartItemId));
      }
    }

    // Write audit event
    const auditRef = db.collection('auditLogs').doc();
    transaction.set(auditRef, {
      actorUid: uid,
      actorRole: 'user',
      action: 'createCheckout',
      targetType: 'checkout',
      targetId: checkoutId,
      createdAt: Timestamp.now(),
      reason: 'Người dùng đặt hàng thành công'
    });

    return {
      checkoutId,
      orderIds,
      totalAmount: totalVnd
    };
  });

  return result;
});

// 2. CANCEL ORDER CALLABLE
export const cancelOrder = functions.https.onCall(async (data, context) => {
  const auth = context.auth;
  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Người dùng chưa đăng nhập');
  }
  const { orderId, reason } = data;
  if (!orderId || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu mã đơn hàng hoặc lý do hủy');
  }

  const actorUid = auth.uid;
  const actorRole = auth.token.role || 'user';

  const orderRef = db.collection('orders').doc(orderId);

  return db.runTransaction(async (transaction) => {
    const orderSnap = await transaction.get(orderRef);
    if (!orderSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Không tìm thấy đơn hàng');
    }

    const orderData = orderSnap.data()!;
    const isBuyer = orderData.buyerId === actorUid;
    const isSeller = orderData.sellerId === actorUid;
    const isAdmin = actorRole === 'admin';

    if (!isBuyer && !isSeller && !isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Bạn không có quyền hủy đơn hàng này');
    }

    const currentStatus = orderData.status;
    if (currentStatus === 'cancelled' || currentStatus === 'completed') {
      throw new functions.https.HttpsError('failed-precondition', 'Đơn hàng đã hoàn thành hoặc đã bị hủy trước đó');
    }

    // Buyer constraints: only cancel before packing (i.e. status is pending or confirmed)
    if (isBuyer && currentStatus !== 'pending' && currentStatus !== 'confirmed') {
      throw new functions.https.HttpsError('failed-precondition', 'Không thể hủy đơn hàng sau khi đã đóng gói hoặc đang vận chuyển');
    }

    // Restore stock for all items
    const items = orderData.itemSnapshots || [];
    for (const item of items) {
      const variantRef = db.collection('products').doc(item.productId).collection('variants').doc(item.variantId);
      const variantSnap = await transaction.get(variantRef);
      if (variantSnap.exists) {
        const currentStock = variantSnap.data()!.stockQuantity ?? 0;
        transaction.update(variantRef, {
          stockQuantity: currentStock + item.quantity
        });
      }
    }

    const timelineEntry = {
      status: 'cancelled',
      note: `Hủy bởi ${isBuyer ? 'Khách hàng' : isSeller ? 'Người bán' : 'Quản trị viên'}. Lý do: ${reason}`,
      createdAt: Timestamp.now()
    };

    transaction.update(orderRef, {
      status: 'cancelled',
      cancelReason: reason,
      updatedAt: Timestamp.now(),
      timeline: FieldValue.arrayUnion(timelineEntry)
    });

    const auditRef = db.collection('auditLogs').doc();
    transaction.set(auditRef, {
      actorUid,
      actorRole,
      action: 'cancelOrder',
      targetType: 'order',
      targetId: orderId,
      createdAt: Timestamp.now(),
      reason: `Hủy đơn hàng: ${reason}`
    });

    return { success: true };
  });
});

// 3. UPDATE ORDER STATUS CALLABLE
export const updateOrderStatus = functions.https.onCall(async (data, context) => {
  const auth = context.auth;
  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Người dùng chưa đăng nhập');
  }
  const { orderId, status } = data;
  if (!orderId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu mã đơn hoặc trạng thái mới');
  }

  const actorUid = auth.uid;
  const actorRole = auth.token.role || 'user';

  const orderRef = db.collection('orders').doc(orderId);

  return db.runTransaction(async (transaction) => {
    const orderSnap = await transaction.get(orderRef);
    if (!orderSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Không tìm thấy đơn hàng');
    }

    const orderData = orderSnap.data()!;
    const isSeller = orderData.sellerId === actorUid;
    const isAdmin = actorRole === 'admin';

    if (!isSeller && !isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Bạn không có quyền cập nhật đơn hàng này');
    }

    const currentStatus = orderData.status;

    let isValidTransition = false;
    if (currentStatus === 'pending') {
      isValidTransition = (status === 'confirmed' || status === 'cancelled');
    } else if (currentStatus === 'confirmed') {
      isValidTransition = (status === 'shipping' || status === 'cancelled');
    } else if (currentStatus === 'shipping') {
      isValidTransition = (status === 'completed' || status === 'cancelled');
    }

    if (!isValidTransition) {
      throw new functions.https.HttpsError('failed-precondition', `Chuyển trạng thái không hợp lệ từ ${currentStatus} sang ${status}`);
    }

    const timelineEntry = {
      status,
      note: `Trạng thái được cập nhật bởi ${isAdmin ? 'Quản trị viên' : 'Người bán'}`,
      createdAt: Timestamp.now()
    };

    transaction.update(orderRef, {
      status,
      updatedAt: Timestamp.now(),
      timeline: FieldValue.arrayUnion(timelineEntry)
    });

    const auditRef = db.collection('auditLogs').doc();
    transaction.set(auditRef, {
      actorUid,
      actorRole,
      action: 'updateOrderStatus',
      targetType: 'order',
      targetId: orderId,
      createdAt: Timestamp.now(),
      reason: `Cập nhật trạng thái đơn hàng sang ${status}`
    });

    return { success: true };
  });
});

// 4. REVIEW SELLER APPLICATION CALLABLE
export const reviewSellerApplication = functions.https.onCall(async (data, context) => {
  const auth = context.auth;
  if (!auth || auth.token.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Chỉ có Quản trị viên mới được quyền thực hiện chức năng này');
  }

  const { applicationId, action, reason } = data;
  if (!applicationId || !action || (action !== 'approve' && action !== 'reject')) {
    throw new functions.https.HttpsError('invalid-argument', 'Tham số duyệt người bán không hợp lệ');
  }

  if (action === 'reject' && !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Bắt buộc phải nhập lý do từ chối');
  }

  const appRef = db.collection('seller_applications').doc(applicationId);
  const appSnap = await appRef.get();
  if (!appSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Không tìm thấy hồ sơ đăng ký');
  }

  const appData = appSnap.data()!;
  if (appData.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'Hồ sơ này đã được xử lý trước đó');
  }

  const applicantUid = appData.uid || applicationId;

  if (action === 'reject') {
    await appRef.update({
      status: 'rejected',
      reason,
      reviewedBy: auth.uid,
      updatedAt: Timestamp.now()
    });

    await db.collection('auditLogs').add({
      actorUid: auth.uid,
      actorRole: 'admin',
      action: 'rejectSellerApplication',
      targetType: 'seller_application',
      targetId: applicationId,
      reason,
      createdAt: Timestamp.now()
    });

    return { success: true };
  } else {
    // Approve seller application
    await db.runTransaction(async (transaction) => {
      transaction.update(appRef, {
        status: 'approved',
        reviewedBy: auth.uid,
        updatedAt: Timestamp.now()
      });

      const userRef = db.collection('users').doc(applicantUid);
      transaction.update(userRef, {
        roleMirror: 'seller',
        updatedAt: Timestamp.now()
      });

      const storeRef = db.collection('stores').doc(applicantUid);
      transaction.set(storeRef, {
        ownerUid: applicantUid,
        name: appData.storeName || appData.displayName || `Cửa hàng ${applicantUid}`,
        slug: appData.storeSlug || `store-${applicantUid}`,
        description: appData.storeDescription || 'Chưa có mô tả',
        status: 'active',
        rating: 5.0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now()
      });

      const auditRef = db.collection('auditLogs').doc();
      transaction.set(auditRef, {
        actorUid: auth.uid,
        actorRole: 'admin',
        action: 'approveSellerApplication',
        targetType: 'seller_application',
        targetId: applicationId,
        createdAt: Timestamp.now(),
        reason: 'Phê duyệt tài khoản người bán thành công'
      });
    });

    await admin.auth().setCustomUserClaims(applicantUid, { role: 'seller' });

    return { success: true };
  }
});

// 5. REVIEW PRODUCT CALLABLE
export const reviewProduct = functions.https.onCall(async (data, context) => {
  const auth = context.auth;
  if (!auth || auth.token.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Chỉ có Quản trị viên mới được quyền thực hiện chức năng này');
  }

  const { productId, action, reason } = data;
  if (!productId || !action || (action !== 'approve' && action !== 'reject' && action !== 'hide')) {
    throw new functions.https.HttpsError('invalid-argument', 'Tham số duyệt sản phẩm không hợp lệ');
  }

  if (action === 'reject' && !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Bắt buộc phải nhập lý do từ chối');
  }

  const productRef = db.collection('products').doc(productId);
  const productSnap = await productRef.get();
  if (!productSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Không tìm thấy sản phẩm');
  }

  let status = 'draft';
  if (action === 'approve') {
    status = 'published';
  } else if (action === 'reject') {
    status = 'rejected';
  } else if (action === 'hide') {
    status = 'draft';
  }

  await productRef.update({
    status,
    rejectReason: action === 'reject' ? reason : null,
    updatedAt: Timestamp.now()
  });

  await db.collection('auditLogs').add({
    actorUid: auth.uid,
    actorRole: 'admin',
    action: `${action}Product`,
    targetType: 'product',
    targetId: productId,
    reason: reason || `Thao tác sản phẩm thành công: ${action}`,
    createdAt: Timestamp.now()
  });

  return { success: true };
});

// 6. SUBMIT REVIEW CALLABLE
export const submitReview = functions.https.onCall(async (data, context) => {
  const auth = context.auth;
  if (!auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Người dùng chưa đăng nhập');
  }

  const { productId, orderId, rating, comment } = data;
  if (!productId || !orderId || !rating || !comment) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu tham số đánh giá bắt buộc');
  }

  if (rating < 1 || rating > 5 || rating % 1 !== 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Rating phải là số nguyên từ 1 đến 5');
  }

  const uid = auth.uid;
  const orderRef = db.collection('orders').doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Không tìm thấy đơn hàng');
  }

  const orderData = orderSnap.data()!;
  if (orderData.buyerId !== uid) {
    throw new functions.https.HttpsError('permission-denied', 'Bạn không sở hữu đơn hàng này');
  }

  if (orderData.status !== 'completed' && orderData.status !== 'delivered') {
    throw new functions.https.HttpsError('failed-precondition', 'Chỉ có thể đánh giá đơn hàng đã giao thành công');
  }

  const items = orderData.itemSnapshots || [];
  const hasProduct = items.some((x: any) => x.productId === productId);
  if (!hasProduct) {
    throw new functions.https.HttpsError('failed-precondition', 'Sản phẩm này không nằm trong đơn hàng');
  }

  const duplicateQuery = await db.collection('reviews')
    .where('buyerId', '==', uid)
    .where('orderId', '==', orderId)
    .where('productId', '==', productId)
    .get();

  if (!duplicateQuery.empty) {
    throw new functions.https.HttpsError('already-exists', 'Bạn đã gửi đánh giá cho sản phẩm này trong đơn hàng này rồi');
  }

  const reviewId = `${orderId}_${productId}`;
  const reviewRef = db.collection('reviews').doc(reviewId);

  await reviewRef.set({
    buyerId: uid,
    buyerName: orderData.shippingAddress?.fullName || 'Người dùng',
    productId,
    orderId,
    rating,
    comment,
    status: 'approved',
    createdAt: Timestamp.now()
  });

  return { success: true };
});

// 7. ORDER TRANSITIONS & NOTIFICATIONS TRIGGER
export const onOrderWrite = functions.firestore.document('orders/{orderId}').onWrite(async (change, context) => {
  const orderId = context.params.orderId;
  const before = change.before.data();
  const after = change.after.data();

  if (!after) return;

  const buyerId = after.buyerId;
  const sellerId = after.sellerId;
  const currentStatus = after.status;
  const oldStatus = before ? before.status : null;

  if (currentStatus !== oldStatus) {
    const notifyBuyerRef = db.collection('notifications').doc(buyerId).collection('items').doc();
    let title = '';
    let body = '';

    if (currentStatus === 'pending') {
      title = 'Đơn hàng mới đã được tạo';
      body = `Đơn hàng ${orderId} của bạn đã được gửi thành công và đang chờ xác nhận.`;
    } else if (currentStatus === 'confirmed') {
      title = 'Đơn hàng đã được xác nhận';
      body = `Đơn hàng ${orderId} của bạn đã được người bán xác nhận và chuẩn bị đóng gói.`;
    } else if (currentStatus === 'shipping') {
      title = 'Đơn hàng đang giao';
      body = `Đơn hàng ${orderId} của bạn đã được giao cho đơn vị vận chuyển.`;
    } else if (currentStatus === 'completed' || currentStatus === 'delivered') {
      title = 'Đơn hàng thành công';
      body = `Đơn hàng ${orderId} của bạn đã được giao thành công.`;
    } else if (currentStatus === 'cancelled') {
      title = 'Đơn hàng đã bị hủy';
      body = `Đơn hàng ${orderId} của bạn đã bị hủy. Lý do: ${after.cancelReason || 'Không có'}`;
    }

    if (title && body) {
      await notifyBuyerRef.set({
        type: 'order_status',
        title,
        body,
        data: { orderId },
        createdAt: Timestamp.now()
      });

      const tokensSnap = await db.collection('users').doc(buyerId).collection('fcm_tokens').get();
      const tokens = tokensSnap.docs.map(doc => doc.id);
      if (tokens.length > 0) {
        const payload = {
          notification: { title, body },
          data: { orderId, click_action: 'FLUTTER_NOTIFICATION_CLICK' }
        };
        try {
          await admin.messaging().sendToDevice(tokens, payload);
        } catch (e) {
          console.error('Error sending FCM to buyer:', e);
        }
      }
    }

    if (currentStatus === 'pending' || currentStatus === 'cancelled') {
      const notifySellerRef = db.collection('notifications').doc(sellerId).collection('items').doc();
      let sellerTitle = '';
      let sellerBody = '';

      if (currentStatus === 'pending') {
        sellerTitle = 'Có đơn hàng mới';
        sellerBody = `Cửa hàng của bạn nhận được đơn hàng mới ${orderId}. Vui lòng xác nhận đơn hàng.`;
      } else if (currentStatus === 'cancelled') {
        sellerTitle = 'Đơn hàng bị hủy';
        sellerBody = `Đơn hàng ${orderId} đã bị hủy bởi ${after.cancelReason ? 'Khách hàng' : 'Hệ thống'}.`;
      }

      await notifySellerRef.set({
        type: 'order_status_seller',
        title: sellerTitle,
        body: sellerBody,
        data: { orderId },
        createdAt: Timestamp.now()
      });

      const tokensSnap = await db.collection('users').doc(sellerId).collection('fcm_tokens').get();
      const tokens = tokensSnap.docs.map(doc => doc.id);
      if (tokens.length > 0) {
        const payload = {
          notification: { title: sellerTitle, body: sellerBody },
          data: { orderId, click_action: 'FLUTTER_NOTIFICATION_CLICK' }
        };
        try {
          await admin.messaging().sendToDevice(tokens, payload);
        } catch (e) {
          console.error('Error sending FCM to seller:', e);
        }
      }
    }

    // Stats updates
    const statsRef = db.collection('stats').doc('global');
    const sellerStatsRef = db.collection('stats').doc(sellerId);
    const totalIncrement = after.totals?.total || 0;

    if (currentStatus === 'completed' || currentStatus === 'delivered') {
      await db.runTransaction(async (transaction) => {
        const globalSnap = await transaction.get(statsRef);
        const globalRevenue = globalSnap.exists ? (globalSnap.data()!.revenueVnd ?? 0) : 0;
        const globalCount = globalSnap.exists ? (globalSnap.data()!.completedOrdersCount ?? 0) : 0;

        transaction.set(statsRef, {
          revenueVnd: globalRevenue + totalIncrement,
          completedOrdersCount: globalCount + 1,
          updatedAt: Timestamp.now()
        }, { merge: true });

        const sellerSnap = await transaction.get(sellerStatsRef);
        const sellerRevenue = sellerSnap.exists ? (sellerSnap.data()!.revenueVnd ?? 0) : 0;
        const sellerCount = sellerSnap.exists ? (sellerSnap.data()!.completedOrdersCount ?? 0) : 0;

        transaction.set(sellerStatsRef, {
          revenueVnd: sellerRevenue + totalIncrement,
          completedOrdersCount: sellerCount + 1,
          updatedAt: Timestamp.now()
        }, { merge: true });
      });
    }
  }
});

// 8. REVIEW RATING ACCUMULATOR TRIGGER
export const onReviewWrite = functions.firestore.document('reviews/{reviewId}').onWrite(async (change, context) => {
  const after = change.after.data();
  if (!after) return;

  const productId = after.productId;
  const reviewsSnap = await db.collection('reviews').where('productId', '==', productId).get();
  const ratings = reviewsSnap.docs.map(doc => doc.data().rating as number);
  const avgRating = ratings.reduce((sum, r) => sum + r, 0) / ratings.length;

  const productRef = db.collection('products').doc(productId);
  await productRef.update({
    rating: avgRating,
    reviewsCount: ratings.length
  });

  const productSnap = await productRef.get();
  if (productSnap.exists) {
    const sellerId = productSnap.data()!.sellerId;
    const productsSnap = await db.collection('products').where('sellerId', '==', sellerId).get();
    const productRatings = productsSnap.docs
      .map(doc => doc.data().rating as number)
      .filter(r => r !== undefined && r !== null && r > 0);
    
    if (productRatings.length > 0) {
      const avgStoreRating = productRatings.reduce((sum, r) => sum + r, 0) / productRatings.length;
      await db.collection('stores').doc(sellerId).update({
        rating: avgStoreRating,
        reviewsCount: productRatings.length
      });
    }
  }
});

// 9. AUTH USER DELETION TRIGGER
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;

  const cartSnap = await db.collection('users').doc(uid).collection('cart').get();
  const batch = db.batch();
  cartSnap.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  await db.collection('users').doc(uid).set({
    displayName: 'Người dùng đã xóa',
    email: '',
    photoUrl: '',
    roleMirror: 'guest',
    status: 'deleted',
    updatedAt: Timestamp.now()
  }, { merge: true });

  console.log(`Successfully processed deletion for user ${uid}`);
});

// 10. SCHEDULED CLEANUP JOB
export const scheduledCleanup = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  console.log('Cleanup job completed');
  return null;
});

// 11. FIRESTORE USER ROLE SYNC TRIGGER (to sync roles to custom claims in auth)
export const onUserWrite = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data) return;
    const role = data.role || data.roleMirror || 'user';
    try {
      await admin.auth().setCustomUserClaims(context.params.userId, { role });
      console.log(`Successfully synced role '${role}' to custom claims for user ${context.params.userId}`);
    } catch (e) {
      console.warn(`Could not set custom claims for user ${context.params.userId}: ${e}`);
    }
  });

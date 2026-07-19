import * as admin from 'firebase-admin';

// Crucial: Set emulator environment variables before importing index.ts
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.GCLOUD_PROJECT = 'test-finalprm-project';

import {
  createCheckout,
  updateOrderStatus,
  reviewProduct
} from './index';

const db = admin.firestore();

async function runTests() {
  console.log('--- STARTING BACKEND INTEGRATION TEST SUITE ---');

  try {
    // 1. Clear existing database collections
    await clearDatabase();
    console.log('✔ Cleaned emulator database');

    // 2. Seed initial data
    await seedInitialData();
    console.log('✔ Seeded mock store, products, and categories');

    // 3. Test: Happy Path createCheckout
    console.log('\n--- Test Case 1: createCheckout Happy Path ---');
    const checkoutData = {
      items: [
        {
          productId: 'prod_pegasus',
          variantId: 'v_peg_42_red',
          quantity: 2,
          cartItemId: 'cart_item_1'
        }
      ],
      address: {
        fullName: 'Nguyễn Văn Hiếu',
        phone: '0987654321',
        addressLine: '123 Đường Lê Lợi',
        city: 'Hồ Chí Minh'
      },
      paymentMethod: 'COD',
      idempotencyKey: 'idemp_key_happy_123'
    };

    const userContext = {
      auth: {
        uid: 'user_1',
        token: { role: 'user' }
      }
    };

    // Run checkout function
    const checkoutResult = await createCheckout.run(checkoutData, userContext as any);
    console.log('Result:', checkoutResult);

    // Verify orders were created in database
    const orderIds = checkoutResult.orderIds;
    if (!orderIds || orderIds.length === 0) {
      throw new Error('No orders returned in checkoutResult');
    }

    const orderDoc = await db.collection('orders').doc(orderIds[0]).get();
    if (!orderDoc.exists) {
      throw new Error(`Order ${orderIds[0]} was not created in Firestore`);
    }

    const orderData = orderDoc.data()!;
    console.log('✔ Order successfully created with status:', orderData.status);
    console.log('✔ Order total amount:', orderData.totals.total);

    // Verify stock was decremented (10 - 2 = 8)
    const variantDoc = await db.collection('products')
      .doc('prod_pegasus')
      .collection('variants')
      .doc('v_peg_42_red')
      .get();
    const currentStock = variantDoc.data()!.stockQuantity;
    console.log('✔ Stock remaining for Pegasus Red Size 42:', currentStock);
    if (currentStock !== 8) {
      throw new Error(`Expected stock to be 8, got ${currentStock}`);
    }

    // 4. Test: Out of Stock validation
    console.log('\n--- Test Case 2: createCheckout Out of Stock ---');
    const outOfStockData = {
      items: [
        {
          productId: 'prod_ultraboost',
          variantId: 'v_ub_41_white', // Only 1 stock
          quantity: 3
        }
      ],
      address: {
        fullName: 'Nguyễn Văn Hiếu',
        phone: '0987654321',
        addressLine: '123 Đường Lê Lợi',
        city: 'Hồ Chí Minh'
      },
      paymentMethod: 'COD',
      idempotencyKey: 'idemp_key_outofstock'
    };

    try {
      await createCheckout.run(outOfStockData, userContext as any);
      throw new Error('Out of stock checkout should have failed');
    } catch (e: any) {
      console.log('✔ Checkout failed as expected:', e.message);
      if (!e.message.includes('không đủ tồn kho') && !e.message.includes('hết hàng')) {
        throw new Error(`Unexpected error message: ${e.message}`);
      }
    }

    // 5. Test: Idempotency checkout replay
    console.log('\n--- Test Case 3: createCheckout Idempotency Replay ---');
    const replayResult = await createCheckout.run(checkoutData, userContext as any);
    console.log('✔ Replay Result orderIds:', replayResult.orderIds);
    if (JSON.stringify(replayResult.orderIds) !== JSON.stringify(orderIds)) {
      throw new Error('Replayed checkout returned different order IDs');
    }

    // 6. Test: Invalid Order Status Transition (pending -> completed)
    console.log('\n--- Test Case 4: Invalid Order Status Transition ---');
    const sellerContext = {
      auth: {
        uid: 'seller_1',
        token: { role: 'seller' }
      }
    };

    try {
      await updateOrderStatus.run({
        orderId: orderIds[0],
        status: 'completed' // Should fail because current status is pending (must go confirmed first)
      }, sellerContext as any);
      throw new Error('Invalid status transition should have failed');
    } catch (e: any) {
      console.log('✔ Transition failed as expected:', e.message);
    }

    // 7. Test: Valid Order Status Transition (pending -> confirmed -> shipping -> completed)
    console.log('\n--- Test Case 5: Valid Order Status Transitions ---');
    await updateOrderStatus.run({
      orderId: orderIds[0],
      status: 'confirmed'
    }, sellerContext as any);

    await updateOrderStatus.run({
      orderId: orderIds[0],
      status: 'shipping'
    }, sellerContext as any);

    const afterTransitionDoc = await db.collection('orders').doc(orderIds[0]).get();
    console.log('✔ Updated order status to:', afterTransitionDoc.data()!.status);
    if (afterTransitionDoc.data()!.status !== 'shipping') {
      throw new Error('Status was not updated correctly to shipping');
    }

    // 8. Test: Admin Moderation Approve Product
    console.log('\n--- Test Case 6: Admin Moderation Approve Product ---');
    const adminContext = {
      auth: {
        uid: 'admin_1',
        token: { role: 'admin' }
      }
    };

    const pendingProductDoc = await db.collection('products').doc('prod_rider').get();
    console.log('Original status of pending product:', pendingProductDoc.data()!.status);

    await reviewProduct.run({
      productId: 'prod_rider',
      action: 'approve'
    }, adminContext as any);

    const approvedProductDoc = await db.collection('products').doc('prod_rider').get();
    console.log('✔ Approved product status:', approvedProductDoc.data()!.status);
    if (approvedProductDoc.data()!.status !== 'published') {
      throw new Error('Product was not published after approval');
    }

    console.log('\n--- ALL TEST CASES PASSED SUCCESSFULLY ---');
    process.exit(0);

  } catch (err) {
    console.error('\n❌ TEST SUITE FAILED:', err);
    process.exit(1);
  }
}

async function clearDatabase() {
  const collections = ['categories', 'users', 'products', 'stores', 'orders', 'checkouts', 'auditLogs', 'reviews', 'stats'];
  for (const col of collections) {
    const snap = await db.collection(col).get();
    const batch = db.batch();
    snap.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  }
}

async function seedInitialData() {
  // Store profile
  await db.collection('stores').doc('seller_1').set({
    ownerUid: 'seller_1',
    name: 'Cửa hàng Sneaker Kings',
    slug: 'sneaker-kings',
    status: 'active',
    rating: 5.0
  });

  // Products
  await db.collection('products').doc('prod_pegasus').set({
    sellerId: 'seller_1',
    storeId: 'seller_1',
    name: 'Nike Air Zoom Pegasus 39',
    basePrice: 2500000.0,
    status: 'published',
    images: ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400']
  });

  await db.collection('products').doc('prod_pegasus').collection('variants').doc('v_peg_42_red').set({
    id: 'v_peg_42_red',
    size: '42',
    color: 'Đỏ',
    stockQuantity: 10,
    priceDifference: 0.0
  });

  await db.collection('products').doc('prod_pegasus').collection('variants').doc('v_peg_43_black').set({
    id: 'v_peg_43_black',
    size: '43',
    color: 'Đen',
    stockQuantity: 5,
    priceDifference: 150000.0
  });

  await db.collection('products').doc('prod_ultraboost').set({
    sellerId: 'seller_1',
    storeId: 'seller_1',
    name: 'Adidas Ultraboost Light',
    basePrice: 3200000.0,
    status: 'published'
  });

  await db.collection('products').doc('prod_ultraboost').collection('variants').doc('v_ub_41_white').set({
    id: 'v_ub_41_white',
    size: '41',
    color: 'Trắng',
    stockQuantity: 1,
    priceDifference: 0.0
  });

  await db.collection('products').doc('prod_rider').set({
    sellerId: 'seller_1',
    storeId: 'seller_1',
    name: 'Puma Future Rider Play On',
    basePrice: 1800000.0,
    status: 'pendingReview'
  });
}

runTests();

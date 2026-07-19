const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

describe('Firestore Security Rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'test-finalprm-project',
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  // --- TESTS FOR PRODUCTS ---
  describe('Products Collection', () => {
    it('allows anyone (even guests) to read products', async () => {
      const guestDb = testEnv.unauthenticatedContext().firestore();
      const productRef = guestDb.collection('products').doc('nike_shoe');
      await assertSucceeds(productRef.get());
      await assertSucceeds(guestDb.collection('products').get());
    });

    it('denies guests (unauthenticated) from creating products', async () => {
      const guestDb = testEnv.unauthenticatedContext().firestore();
      const productRef = guestDb.collection('products').doc('nike_shoe');
      await assertFails(productRef.set({ name: 'Nike Air', price: 100 }));
    });

    it('denies regular users (no special claims) from creating products', async () => {
      const userDb = testEnv.authenticatedContext('user_1', { role: 'user' }).firestore();
      const productRef = userDb.collection('products').doc('nike_shoe');
      await assertFails(productRef.set({ name: 'Nike Air', price: 100 }));
    });

    it('allows sellers (claim role: seller) to create products', async () => {
      const sellerDb = testEnv.authenticatedContext('seller_1', { role: 'seller' }).firestore();
      const productRef = sellerDb.collection('products').doc('nike_shoe');
      await assertSucceeds(productRef.set({ name: 'Nike Air', price: 100, sellerId: 'seller_1', status: 'draft' }));
    });

    it('allows admins (claim role: admin) to create/update/delete products', async () => {
      const adminDb = testEnv.authenticatedContext('admin_1', { role: 'admin' }).firestore();
      const productRef = adminDb.collection('products').doc('nike_shoe');
      await assertSucceeds(productRef.set({ name: 'Nike Air', price: 100, sellerId: 'seller_1', status: 'draft' }));
      await assertSucceeds(productRef.update({ price: 120 }));
      await assertSucceeds(productRef.delete());
    });
  });

  // --- TESTS FOR USER PROFILES ---
  describe('Users Collection', () => {
    it('denies guests from reading or writing user profiles', async () => {
      const guestDb = testEnv.unauthenticatedContext().firestore();
      const profileRef = guestDb.collection('users').doc('user_1');
      await assertFails(profileRef.get());
      await assertFails(profileRef.set({ displayName: 'Guest Attempt' }));
    });

    it('allows user to read their own profile, but denies reading others', async () => {
      const user1Db = testEnv.authenticatedContext('user_1', { role: 'user' }).firestore();
      const profile1Ref = user1Db.collection('users').doc('user_1');
      const profile2Ref = user1Db.collection('users').doc('user_2');

      await assertSucceeds(profile1Ref.get());
      await assertFails(profile2Ref.get());
    });

    it('allows user to create their own profile without role/status fields', async () => {
      const user1Db = testEnv.authenticatedContext('user_1', { role: 'user' }).firestore();
      const profileRef = user1Db.collection('users').doc('user_1');
      await assertSucceeds(profileRef.set({ displayName: 'John Doe', phone: '0987654321' }));
    });

    it('denies user from creating their profile containing role/status fields', async () => {
      const user1Db = testEnv.authenticatedContext('user_1', { role: 'user' }).firestore();
      const profileRef = user1Db.collection('users').doc('user_1');
      await assertFails(profileRef.set({ displayName: 'Fake Admin', role: 'admin' }));
      await assertFails(profileRef.set({ displayName: 'Fake Seller', status: 'approved' }));
    });

    it('allows user to update their profile without changing role/status', async () => {
      // 1. Admin creates profile with role 'user'
      const adminDb = testEnv.authenticatedContext('admin_1', { role: 'admin' }).firestore();
      await adminDb.collection('users').doc('user_1').set({ displayName: 'John Doe', role: 'user', status: 'active' });

      // 2. User updates their own profile
      const user1Db = testEnv.authenticatedContext('user_1', { role: 'user' }).firestore();
      const profileRef = user1Db.collection('users').doc('user_1');

      // Update allowed field
      await assertSucceeds(profileRef.update({ displayName: 'John Doe Edit' }));
      // Attempt to change role -> fails
      await assertFails(profileRef.update({ role: 'admin' }));
      // Attempt to change status -> fails
      await assertFails(profileRef.update({ status: 'suspended' }));
    });

    it('allows admin to read/write/delete any user profile', async () => {
      const adminDb = testEnv.authenticatedContext('admin_1', { role: 'admin' }).firestore();
      const profileRef = adminDb.collection('users').doc('user_1');

      await assertSucceeds(profileRef.set({ displayName: 'John Doe', role: 'user', status: 'active' }));
      await assertSucceeds(profileRef.get());
      await assertSucceeds(profileRef.update({ role: 'seller' }));
      await assertSucceeds(profileRef.delete());
    });

    it('denies non-admin users from deleting any user profiles', async () => {
      const user1Db = testEnv.authenticatedContext('user_1', { role: 'user' }).firestore();
      // Attempt to delete own profile -> fails
      await assertFails(user1Db.collection('users').doc('user_1').delete());
    });
  });
});

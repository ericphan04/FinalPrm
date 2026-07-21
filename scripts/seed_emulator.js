/**
 * Seed base data for Firebase Emulator.
 * Run: node scripts/seed_emulator.js
 */
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8090';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

initializeApp({ projectId: 'shoestoremarketplace' });

const db = getFirestore();

async function seed() {
  console.log('Seeding Firestore Emulator...');

  const categories = [
    {
      id: 'shoes',
      name: 'Shoes',
      slug: 'shoes',
      sortOrder: 1,
      status: 'active',
      imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
    },
    {
      id: 'sandals',
      name: 'Sandals',
      slug: 'sandals',
      sortOrder: 2,
      status: 'active',
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
    },
    {
      id: 'accessories',
      name: 'Accessories',
      slug: 'accessories',
      sortOrder: 3,
      status: 'active',
      imageUrl: 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=400',
    },
  ];

  for (const category of categories) {
    const { id, ...data } = category;
    await db.collection('categories').doc(id).set(data);
    console.log(`Category: ${category.name}`);
  }

  const users = [
    {
      id: 'admin_1',
      displayName: 'Admin',
      email: 'admin@example.com',
      roleMirror: 'admin',
      status: 'active',
      avatarUrl: '',
      phone: '',
    },
    {
      id: 'seller_1',
      displayName: 'Branch 01',
      email: 'seller@example.com',
      roleMirror: 'seller',
      status: 'active',
      avatarUrl: '',
      phone: '',
    },
    {
      id: 'user_1',
      displayName: 'Customer',
      email: 'user@example.com',
      roleMirror: 'user',
      status: 'active',
      avatarUrl: '',
      phone: '',
    },
  ];

  for (const user of users) {
    const { id, ...data } = user;
    await db.collection('users').doc(id).set({
      ...data,
      createdAt: Timestamp.now(),
    });
    console.log(`User: ${user.email}`);
  }

  await db.collection('stores').doc('seller_1').set({
    ownerUid: 'seller_1',
    name: 'Branch 01',
    slug: 'branch-01',
    description: 'Company branch account.',
    logoUrl: 'https://images.unsplash.com/photo-1472851294608-062f824d296e?w=400',
    status: 'active',
    rating: 5.0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  console.log('Store: Branch 01');

  console.log('Product seeding disabled. Old marketplace demo products will not be recreated.');
  console.log('Seed completed: 3 categories, 3 users, 1 store, 0 products.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});

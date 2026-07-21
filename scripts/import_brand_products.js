const fs = require('fs');
const vm = require('vm');

const apiKey = process.env.FIREBASE_API_KEY || 'AIzaSyCiAWCWokDMAKDOeI1fKBanXSBju13RjMs';
const projectId = process.env.FIREBASE_PROJECT_ID || 'shoestoremarketplace';
const adminEmail = process.env.FIREBASE_ADMIN_EMAIL || 'admin@example.com';
const adminPassword = process.env.FIREBASE_ADMIN_PASSWORD || 'admin123';
const filePath = process.argv[2];

if (!filePath) {
  console.error('Usage: node scripts/import_brand_products.js <products-js-file>');
  process.exit(1);
}

function parseProducts(input) {
  const code = input.replace(/^\s*const\s+products\s*=/, 'products =');
  const sandbox = { products: [] };
  vm.createContext(sandbox);
  vm.runInContext(code, sandbox, { timeout: 5000 });
  if (!Array.isArray(sandbox.products)) {
    throw new Error('Input file does not define a products array.');
  }
  return sandbox.products;
}

async function signIn() {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: adminEmail,
        password: adminPassword,
        returnSecureToken: true,
      }),
    },
  );
  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Admin sign-in failed: ${JSON.stringify(data)}`);
  }
  return { idToken: data.idToken, uid: data.localId, email: data.email };
}

async function firestoreGet(path, idToken) {
  const response = await fetch(firestoreUrl(path), {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (response.status === 404) return null;
  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Firestore get failed ${path}: ${JSON.stringify(data)}`);
  }
  return data;
}

async function firestorePatch(path, body, idToken) {
  const response = await fetch(firestoreUrl(path), {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Firestore write failed ${path}: ${JSON.stringify(data)}`);
  }
  return data;
}

function firestoreUrl(path) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`;
}

function fieldValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (Number.isInteger(value)) return { integerValue: String(value) };
  if (typeof value === 'number') return { doubleValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(fieldValue) } };
  }
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, item]) => [key, fieldValue(item)]),
        ),
      },
    };
  }
  return { stringValue: String(value) };
}

function documentBody(data) {
  return {
    fields: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, fieldValue(value)]),
    ),
  };
}

function documentToPlain(doc) {
  const fields = doc?.fields || {};
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, plainValue(value)]),
  );
}

function plainValue(value) {
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(plainValue);
  }
  if ('mapValue' in value) {
    return documentToPlain(value.mapValue);
  }
  return null;
}

async function listStores(idToken) {
  const response = await fetch(firestoreUrl('stores'), {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Cannot load stores: ${JSON.stringify(data)}`);
  }
  return (data.documents || []).map((doc) => {
    const id = doc.name.split('/').pop();
    const plain = documentToPlain(doc);
    return {
      id,
      name: plain.name || plain.displayName || id,
      address: plain.address || '',
      slug: plain.slug || '',
    };
  }).filter((store) => {
    if (process.env.IMPORT_ALL_STORES === 'true') return true;
    const slug = store.slug.toLowerCase();
    const name = store.name.toLowerCase();
    return slug.startsWith('chi-nhanh-') || name.startsWith('chi nhánh');
  });
}

function buildBranchInventory(stores, stockQuantity) {
  if (stores.length === 0) return [];
  const base = Math.floor(stockQuantity / stores.length);
  let remainder = stockQuantity % stores.length;
  return stores.map((store) => {
    const stock = base + (remainder > 0 ? 1 : 0);
    remainder -= 1;
    return {
      branchId: store.id,
      storeId: store.id,
      branchName: store.name,
      address: store.address,
      stockQuantity: stock,
    };
  });
}

function normalizeProduct(product, stores) {
  const variants = (product.variants || []).map((variant, index) => ({
    id: stringOrFallback(variant.id, `${product.id}_variant_${index + 1}`),
    size: stringOrFallback(variant.size, 'Default'),
    color: stringOrFallback(variant.color, 'Default'),
    sku: stringOrFallback(variant.sku, `${product.id}-${index + 1}`),
    stockQuantity: numberOrZero(variant.stockQuantity),
    priceDifference: numberOrZero(variant.priceDifference),
  }));
  const totalStock = variants.reduce((sum, variant) => sum + variant.stockQuantity, 0);

  return {
    id: stringOrFallback(product.id, `prod_${Date.now()}`),
    name: stringOrFallback(product.name, 'Unnamed product'),
    description: stringOrFallback(product.description, ''),
    categoryId: stringOrFallback(product.categoryId, 'shoes'),
    basePrice: numberOrZero(product.basePrice),
    sellerId: 'admin',
    ownerType: 'brand',
    ownerId: 'admin',
    status: 'published',
    rejectReason: null,
    images: Array.isArray(product.images) ? product.images.filter((url) => typeof url === 'string') : [],
    isAvailable: product.isAvailable !== false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    variants,
    branchInventory: buildBranchInventory(stores, totalStock),
  };
}

function stringOrFallback(value, fallback) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function numberOrZero(value) {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

async function ensureCategories(products, idToken) {
  const categoryIds = [...new Set(products.map((product) => product.categoryId).filter(Boolean))];
  for (const id of categoryIds) {
    const existing = await firestoreGet(`categories/${encodeURIComponent(id)}`, idToken);
    if (existing) continue;
    await firestorePatch(
      `categories/${encodeURIComponent(id)}`,
      documentBody({
        name: categoryName(id),
        slug: id,
        status: 'active',
        sortOrder: id === 'nike' ? 10 : id === 'adidas' ? 20 : 99,
      }),
      idToken,
    );
  }
}

function categoryName(id) {
  if (id === 'nike') return 'Nike';
  if (id === 'adidas') return 'adidas';
  return id;
}

async function main() {
  const raw = fs.readFileSync(filePath, 'utf8');
  const sourceProducts = parseProducts(raw);
  const auth = await signIn();
  const idToken = auth.idToken;
  await firestorePatch(
    `users/${encodeURIComponent(auth.uid)}`,
    documentBody({
      displayName: 'Admin',
      email: auth.email || adminEmail,
      role: 'admin',
      roleMirror: 'admin',
      status: 'active',
      updatedAt: new Date().toISOString(),
    }),
    idToken,
  );
  const stores = await listStores(idToken);
  const products = sourceProducts.map((product) => normalizeProduct(product, stores));

  await ensureCategories(products, idToken);

  let imported = 0;
  for (const product of products) {
    const { id, ...data } = product;
    await firestorePatch(`products/${encodeURIComponent(id)}`, documentBody(data), idToken);
    imported += 1;
    console.log(`Imported ${id}: ${product.name}`);
  }

  console.log(`Done. Imported ${imported} products. Branches used: ${stores.length}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

const path = require('path');
const dotenv = require('dotenv');
const { MongoClient } = require('mongodb');

dotenv.config({ path: path.join(__dirname, 'env.development') });
const uri = process.env.MONGODB_URI;

function gatherPaths(obj, prefix = '') {
  const entries = [];
  if (obj && typeof obj === 'object' && !Array.isArray(obj)) {
    for (const [key, value] of Object.entries(obj)) {
      const pathKey = prefix ? `${prefix}.${key}` : key;
      entries.push(...gatherPaths(value, pathKey));
    }
  } else if (Array.isArray(obj)) {
    obj.forEach((item, index) => {
      entries.push(...gatherPaths(item, `${prefix}[${index}]`));
    });
  } else if (typeof obj === 'string') {
    if (obj.includes('http://localhost') || obj.includes('http://10.0.2.2') || obj.includes('/uploads/') || obj.startsWith('http') || obj.length > 1000) {
      entries.push({ path: prefix, value: obj });
    }
  }
  return entries;
}

(async () => {
  if (!uri) {
    console.error('MONGODB_URI missing');
    process.exit(1);
  }
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db('mainpage');
  const doc = await db.collection('mainPageInfo').findOne({});
  const entries = gatherPaths(doc);
  for (const e of entries) {
    console.log(`${e.path}: ${e.value}`);
  }
  await client.close();
})();

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
    const lower = obj.toLowerCase();
    if (lower.includes('http://localhost') || lower.includes('http://10.0.2.2') || lower.includes('/uploads/') || lower.includes('/api/images/') || lower.includes('base64,') || (prefix.toLowerCase().includes('photo') && obj.length > 20) || (prefix.toLowerCase().includes('image') && obj.length > 20)) {
      entries.push({ path: prefix, value: obj, len: obj.length });
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
    const short = e.value.length > 200 ? e.value.slice(0, 150) + '...' : e.value;
    console.log(`${e.path} [len=${e.len}]: ${short}`);
  }
  await client.close();
})();

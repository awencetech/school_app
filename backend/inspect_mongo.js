const path = require('path');
const dotenv = require('dotenv');
const { MongoClient } = require('mongodb');

dotenv.config({ path: path.join(__dirname, 'env.development') });
const uri = process.env.MONGODB_URI;
(async () => {
  if (!uri) {
    console.error('MONGODB_URI missing');
    process.exit(1);
  }
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db('mainpage');
  const doc = await db.collection('mainPageInfo').findOne({});
  console.log(JSON.stringify(doc, null, 2));
  await client.close();
})();

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
  try {
    await client.connect();
    const db = client.db();
    const names = ['admin-creds', 'staff-creds', 'student-creds', 'users'];

    for (const name of names) {
      const coll = db.collection(name);
      const count = await coll.countDocuments();
      const docs = await coll.find({}).limit(5).toArray();
      console.log(`\n=== COLLECTION ${name} (${count}) ===`);
      console.log(JSON.stringify(docs, null, 2));
    }
  } catch (error) {
    console.error('Mongo inspect error:', error);
  } finally {
    await client.close();
  }
})();

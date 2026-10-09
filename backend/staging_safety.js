async function runStartupDatabaseSetup(setting, { ensureIndexes, migrations }) {
  if (setting !== 'true') return false;

  await ensureIndexes();
  for (const migration of migrations) {
    await migration();
  }
  return true;
}

function createMongoReadinessHandler(getClient, databaseName) {
  return async (_req, res) => {
    const client = getClient();
    if (!client) {
      return res.status(503).json({ status: 'not_ready' });
    }

    try {
      await client.db(databaseName).command({ ping: 1 });
      return res.status(200).json({ status: 'ready' });
    } catch (_error) {
      console.warn('MongoDB readiness ping failed.');
      return res.status(503).json({ status: 'not_ready' });
    }
  };
}

async function uploadGroupPhotoToGridFS(imageBucket, file, createUrl) {
  if (!imageBucket) {
    throw new Error('GridFS bucket is not initialized');
  }

  const uploadStream = imageBucket.openUploadStream(file.originalname, {
    metadata: { contentType: file.mimetype },
  });

  await new Promise((resolve, reject) => {
    uploadStream.on('finish', resolve);
    uploadStream.on('error', reject);
    uploadStream.end(file.buffer);
  });

  return createUrl(uploadStream.id);
}

module.exports = {
  createMongoReadinessHandler,
  runStartupDatabaseSetup,
  uploadGroupPhotoToGridFS,
};

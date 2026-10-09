const { MongoClient } = require('mongodb');
const {
  describeMongoConnectionFailure,
  readBackendConfig,
  validateBackendConfig,
  validateStagingMongoTarget,
} = require('./staging_safety');

async function main() {
  const config = readBackendConfig(process.env);
  validateBackendConfig(config);

  if (config.runStartupMigrations !== 'false') {
    throw new Error('Read-only staging diagnostic requires RUN_STARTUP_MIGRATIONS=false.');
  }

  const uri = validateStagingMongoTarget(config);
  const client = new MongoClient(uri, { serverSelectionTimeoutMS: 10000 });

  try {
    await client.connect();
    await client.db('mmhs_staging').command({ ping: 1 });
    console.log('Read-only MongoDB ping succeeded for the configured staging target.');
  } finally {
    await client.close();
  }
}

main().catch((error) => {
  console.error(describeMongoConnectionFailure(error));
  process.exitCode = 1;
});

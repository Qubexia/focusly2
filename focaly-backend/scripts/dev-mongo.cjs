/**
 * Starts an in-memory MongoDB and keeps it alive for local admin/API work.
 *
 *   node scripts/dev-mongo.cjs
 *
 * Writes the URI to .mongo-uri and patches MONGO_URI in .env.
 */
const fs = require('fs');
const path = require('path');
const { MongoMemoryServer } = require('mongodb-memory-server');

async function main() {
  const mongod = await MongoMemoryServer.create({
    instance: {
      dbName: 'focaly',
      // First boot after binary download is slow on Windows.
      launchTimeout: 120_000,
    },
  });
  const uri = mongod.getUri();
  const root = path.join(__dirname, '..');
  const uriFile = path.join(root, '.mongo-uri');
  const envFile = path.join(root, '.env');

  fs.writeFileSync(uriFile, uri, 'utf8');

  if (fs.existsSync(envFile)) {
    let env = fs.readFileSync(envFile, 'utf8');
    if (/^MONGO_URI=/m.test(env)) {
      env = env.replace(/^MONGO_URI=.*$/m, `MONGO_URI=${uri}`);
    } else {
      env += `\nMONGO_URI=${uri}\n`;
    }
    fs.writeFileSync(envFile, env, 'utf8');
  }

  console.log(`MongoMemoryServer ready: ${uri}`);
  console.log('Leave this process running. Ctrl+C to stop.');

  const shutdown = async () => {
    await mongod.stop();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);

  // Keep alive
  await new Promise(() => {});
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

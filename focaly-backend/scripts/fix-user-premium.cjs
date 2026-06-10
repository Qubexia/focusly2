const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

function envValue(key) {
  const envPath = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return process.env[key] ?? '';
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const m = line.match(new RegExp('^' + key + '=(.*)$'));
    if (m) return m[1];
  }
  return process.env[key] ?? '';
}

async function main() {
  const uri = envValue('MONGO_URI') || 'mongodb://localhost:27017/focaly';
  await mongoose.connect(uri);
  const db = mongoose.connection.db;

  const canceled = await db.collection('subscriptions').find({ status: 'canceled' }).toArray();
  for (const sub of canceled) {
    const userId = sub.userId?.toString?.() ?? String(sub.userId);
    await db.collection('users').updateOne(
      { _id: new mongoose.Types.ObjectId(userId) },
      { $set: { plan: 'free', premiumUntil: null } },
    );
    const user = await db.collection('users').findOne({ _id: new mongoose.Types.ObjectId(userId) });
    console.log('Synced', userId, '-> plan:', user?.plan);
  }

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

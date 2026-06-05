/** Prints the most recent AI jobs (status + failureReason) from MongoDB. */
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

function envValue(key) {
  const envPath = path.join(__dirname, '..', '.env');
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const m = line.match(new RegExp('^' + key + '=(.*)$'));
    if (m) return m[1];
  }
  return null;
}

async function main() {
  const uri = envValue('MONGO_URI') || 'mongodb://localhost:27017/focaly';
  await mongoose.connect(uri);
  const jobs = await mongoose.connection.db
    .collection('ai_jobs')
    .find({})
    .sort({ createdAt: -1 })
    .limit(5)
    .toArray();

  for (const j of jobs) {
    console.log('---');
    console.log('id          :', j._id.toString());
    console.log('status      :', j.status);
    console.log('subjectId   :', j.subjectId?.toString?.() ?? j.subjectId);
    console.log('chapterId   :', j.chapterId?.toString?.() ?? j.chapterId);
    console.log('pdfKeys     :', j.pdfKeys);
    console.log('imageKeys   :', j.imageKeys);
    console.log('failureReason:', j.failureReason);
    console.log('createdAt   :', j.createdAt);
  }
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

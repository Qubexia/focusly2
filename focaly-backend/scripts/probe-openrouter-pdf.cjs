/**
 * Standalone smoke test: sends a real PDF to OpenRouter (via the OpenAI SDK),
 * exactly mirroring the worker's generateStudyPackFromPdfs(), and prints the
 * study pack. Validates the OpenRouter file-parser + Kimi path end to end.
 *
 * Run: node scripts/probe-openrouter-pdf.cjs
 */
const fs = require('fs');
const path = require('path');
const OpenAI = require('openai');

/** Builds a minimal valid single-page PDF with the given text lines. */
function buildPdf(lines) {
  let content = 'BT /F1 14 Tf 50 740 Td 18 TL\n';
  for (const line of lines) content += `(${line}) Tj T*\n`;
  content += 'ET';

  const objs = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    `<< /Length ${content.length} >>\nstream\n${content}\nendstream`,
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];

  let body = '%PDF-1.4\n';
  const offsets = [];
  objs.forEach((obj, i) => {
    offsets.push(body.length);
    body += `${i + 1} 0 obj\n${obj}\nendobj\n`;
  });

  const xrefStart = body.length;
  let xref = `xref\n0 ${objs.length + 1}\n0000000000 65535 f \n`;
  for (const off of offsets) xref += String(off).padStart(10, '0') + ' 00000 n \n';
  const trailer = `trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`;

  return Buffer.from(body + xref + trailer, 'latin1');
}

function loadEnv() {
  const envPath = path.join(__dirname, '..', '.env');
  const out = {};
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

async function main() {
  const env = loadEnv();
  const apiKey = env.OPENAI_API_KEY;
  const baseURL = env.OPENAI_BASE_URL || undefined;
  const model = env.OPENAI_MODEL || 'gpt-4o-mini';

  console.log('baseURL:', baseURL);
  console.log('model  :', model);
  console.log('key    :', apiKey ? apiKey.slice(0, 10) + '…' : '(missing)');

  // Generate a small, text-rich PDF locally and base64-encode it (like GridFS read).
  const pdf = buildPdf([
    'The Water Cycle',
    'Water evaporates from oceans and lakes due to heat from the sun.',
    'The water vapor rises and condenses into clouds.',
    'It then falls back to earth as precipitation: rain or snow.',
    'Water flows through rivers back to the oceans, and the cycle repeats.',
    'Photosynthesis lets plants convert sunlight into chemical energy.',
  ]);
  const base64 = pdf.toString('base64');
  console.log('Generated PDF bytes:', pdf.length, '(base64 len', base64.length + ')');

  const openai = new OpenAI({
    apiKey,
    baseURL,
    defaultHeaders: baseURL
      ? { 'HTTP-Referer': 'https://focaly.app', 'X-Title': 'Focaly' }
      : undefined,
  });

  const instruction = `Return ONLY JSON with this schema:
{
  "summary": "string (max 800 chars)",
  "flashcards": [ { "front": "string", "back": "string" } ],
  "questions": [ { "question": "string", "answer": "string" } ]
}
Rules:
- summary <= 800 characters
- flashcards: exactly 6 items
- questions: exactly 5 items
- Use clear Arabic (or the same language as the source material)`;

  const body = {
    model,
    temperature: 0.2,
    messages: [
      {
        role: 'system',
        content:
          'You are a study assistant. You must output valid JSON that matches the requested schema only.',
      },
      {
        role: 'user',
        content: [
          { type: 'text', text: `Read the attached PDF document(s) and generate a compact study pack.\n\n${instruction}` },
          {
            type: 'file',
            file: { filename: 'sample.pdf', file_data: `data:application/pdf;base64,${base64}` },
          },
        ],
      },
    ],
    plugins: baseURL ? [{ id: 'file-parser', pdf: { engine: 'cloudflare-ai' } }] : undefined,
  };

  console.log('\nCalling model…');
  const started = Date.now();
  const completion = await openai.chat.completions.create(body);
  console.log('Done in', ((Date.now() - started) / 1000).toFixed(1), 's');

  const raw = completion.choices?.[0]?.message?.content ?? '';
  console.log('\n--- RAW MODEL OUTPUT ---\n' + raw.slice(0, 2000));

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    const match = raw.match(/\{[\s\S]*\}/);
    parsed = match ? JSON.parse(match[0]) : null;
  }
  console.log('\n--- PARSED ---');
  console.log('summary?', typeof parsed?.summary === 'string' && parsed.summary.length > 0);
  console.log('flashcards:', Array.isArray(parsed?.flashcards) ? parsed.flashcards.length : 'none');
  console.log('questions :', Array.isArray(parsed?.questions) ? parsed.questions.length : 'none');
  console.log('usage     :', completion.usage);
}

main().catch((e) => {
  console.error('\n[ERROR]', e?.status || '', e?.message || e);
  if (e?.error) console.error(JSON.stringify(e.error, null, 2));
  process.exit(1);
});

/**
 * Smoke test: sends a real PDF to Google Gemini (generateContent, inline PDF),
 * mirroring the worker's generateStudyPackFromPdfsGemini(). Validates the key,
 * model, and that Gemini reads the PDF and returns a study pack.
 *
 * Run: node scripts/probe-gemini-pdf.cjs
 */
const fs = require('fs');
const path = require('path');

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

function env(key) {
  const p = path.join(__dirname, '..', '.env');
  for (const line of fs.readFileSync(p, 'utf8').split(/\r?\n/)) {
    const m = line.match(new RegExp('^' + key + '=(.*)$'));
    if (m) return m[1];
  }
  return null;
}

async function callGemini(authMode) {
  const apiKey = env('GEMINI_API_KEY');
  const model = env('GEMINI_MODEL') || 'gemini-2.5-flash';
  const base64 = buildPdf([
    'The Water Cycle',
    'Water evaporates from oceans and lakes due to heat from the sun.',
    'The water vapor rises and condenses into clouds.',
    'It then falls back to earth as precipitation: rain or snow.',
    'Water flows through rivers back to the oceans, and the cycle repeats.',
    'Photosynthesis lets plants convert sunlight into chemical energy.',
  ]).toString('base64');

  let url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  const headers = { 'Content-Type': 'application/json' };
  if (authMode === 'header') headers['x-goog-api-key'] = apiKey;
  else if (authMode === 'bearer') headers['Authorization'] = `Bearer ${apiKey}`;
  else url += `?key=${encodeURIComponent(apiKey)}`;

  const body = {
    systemInstruction: { parts: [{ text: 'You are a study assistant. Output only valid JSON.' }] },
    contents: [
      {
        role: 'user',
        parts: [
          { text: 'Read the attached PDF and return JSON: {"summary":"...", "flashcards":[{"front","back"}], "questions":[{"question","answer"}]}. flashcards: 6, questions: 5.' },
          { inline_data: { mime_type: 'application/pdf', data: base64 } },
        ],
      },
    ],
    generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
  };

  const res = await fetch(url, { method: 'POST', headers, body: JSON.stringify(body) });
  return { status: res.status, ok: res.ok, text: await res.text() };
}

async function main() {
  console.log('model:', env('GEMINI_MODEL'));
  console.log('key  :', (env('GEMINI_API_KEY') || '').slice(0, 8) + '…\n');

  for (const mode of ['header', 'query', 'bearer']) {
    console.log(`=== auth mode: ${mode} ===`);
    try {
      const r = await callGemini(mode);
      console.log('HTTP', r.status, r.ok ? 'OK' : 'FAIL');
      if (r.ok) {
        const json = JSON.parse(r.text);
        const raw = json.candidates?.[0]?.content?.parts?.map((p) => p.text).join('') ?? '';
        console.log('--- MODEL OUTPUT (first 1500) ---\n' + raw.slice(0, 1500));
        const parsed = JSON.parse(raw.match(/\{[\s\S]*\}/)?.[0] ?? '{}');
        console.log('\nsummary?', !!parsed.summary, '| flashcards:', parsed.flashcards?.length, '| questions:', parsed.questions?.length);
        console.log('usage:', json.usageMetadata);
        return; // success — stop trying other modes
      } else {
        console.log('error body:', r.text.slice(0, 400), '\n');
      }
    } catch (e) {
      console.log('threw:', e.message, '\n');
    }
  }
  console.log('\nAll auth modes failed.');
  process.exit(1);
}

main();

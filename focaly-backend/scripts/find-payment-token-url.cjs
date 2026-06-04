(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  let idx = 0;
  while ((idx = main.indexOf('payment_token', idx)) >= 0) {
    const snippet = main.slice(Math.max(0, idx - 120), idx + 180);
    if (snippet.includes('get(') || snippet.includes('search') || snippet.includes('props')) {
      console.log('---');
      console.log(snippet);
    }
    idx += 12;
  }
})();

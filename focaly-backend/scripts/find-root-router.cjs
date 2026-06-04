(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  for (const needle of ['location.search', 'get("payment_token")', "get('payment_token')"]) {
    let idx = 0;
    let n = 0;
    while (n < 3 && (idx = main.indexOf(needle, idx)) >= 0) {
      console.log('\n---', needle, n, '---');
      console.log(main.slice(idx - 150, idx + 250));
      idx += needle.length;
      n++;
    }
  }
})();

(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const paths = main.match(/acceptance\/payments\/[a-zA-Z0-9_/?&=-]+/g) ?? [];
  console.log('payment paths', [...new Set(paths)]);

  const idx = main.indexOf('standalone"===a');
  console.log('\nstandalone branch:', main.slice(idx - 100, idx + 350));

  const idx2 = main.indexOf('loadData",value:function');
  console.log('\nloadData:', main.slice(idx2, idx2 + 600));
})();

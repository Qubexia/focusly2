(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const idx = main.indexOf('Ac=function');
  if (idx < 0) {
    const idx2 = main.indexOf('var Ac=');
    console.log('var Ac', main.slice(idx2, idx2 + 2000));
  } else {
    console.log(main.slice(idx, idx + 2000));
  }
})();

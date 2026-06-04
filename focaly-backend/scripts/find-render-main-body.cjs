(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const idx = main.indexOf('render_main_body');
  console.log(main.slice(idx, idx + 2500));
})();

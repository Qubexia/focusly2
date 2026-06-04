(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const idx = main.indexOf('invaild_link');
  const start = main.lastIndexOf('key:"render"', idx);
  console.log(main.slice(start, start + 800));
})();

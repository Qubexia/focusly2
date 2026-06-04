(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const anchor = 'Ac=function(e){function a(e){var t;';
  const start = main.indexOf(anchor);
  const end = main.indexOf('Object(m.a)(a,e)', start);
  console.log(main.slice(start, Math.min(start + 8000, end)));
})();

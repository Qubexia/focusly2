(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const idx = main.indexOf('gc.challenge');
  console.log('gc.challenge count', (main.match(/gc\.challenge/g) || []).length);
  console.log(main.slice(idx - 300, idx + 200));

  const idx2 = main.indexOf('componentDidMount",value:function(){this.loadData');
  console.log('\nloadData mount', main.slice(idx2, idx2 + 400));
})();

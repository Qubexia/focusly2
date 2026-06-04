(async () => {
  const main = await fetch(
    'https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js',
  ).then((r) => r.text());

  const anchor = 'load_current_method=function';
  const start = main.lastIndexOf('key:"render"', main.indexOf(anchor));
  console.log('render before load_current_method:', main.slice(start, start + 600));

  const anchor2 = main.indexOf('invaild_link_message:"invaild url, missing payment_token."');
  const render2 = main.indexOf('key:"render"', anchor2);
  console.log('\nrender after missing token:', main.slice(render2, render2 + 600));
})();

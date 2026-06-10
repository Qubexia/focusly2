export function renderPaymobHostedCheckoutScript(view: {
  payUrl: string;
  appSuccessUrl: string;
  appFailureUrl: string;
}): string {
  return `(function () {
  const form = document.getElementById('pay-form');
  const submitBtn = document.getElementById('submit');
  const messageEl = document.getElementById('message');
  const successUrl = ${JSON.stringify(view.appSuccessUrl)};
  const failureUrl = ${JSON.stringify(view.appFailureUrl)};
  const payUrl = ${JSON.stringify(view.payUrl)};

  function showMessage(text, ok) {
    messageEl.hidden = false;
    messageEl.textContent = text;
    messageEl.className = 'msg ' + (ok ? 'ok' : 'err');
  }

  function digits(value) {
    return (value || '').replace(/\\D/g, '');
  }

  document.getElementById('number').addEventListener('input', function (event) {
    const raw = digits(event.target.value).slice(0, 16);
    event.target.value = raw.replace(/(.{4})/g, '$1 ').trim();
  });

  document.getElementById('expiry').addEventListener('input', function (event) {
    let raw = digits(event.target.value).slice(0, 4);
    if (raw.length >= 3) raw = raw.slice(0, 2) + '/' + raw.slice(2);
    event.target.value = raw;
  });

  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    messageEl.hidden = true;
    submitBtn.disabled = true;

    const expiry = document.getElementById('expiry').value.split('/');
    const payload = {
      name: document.getElementById('name').value.trim(),
      number: digits(document.getElementById('number').value),
      expiryMonth: (expiry[0] || '').trim(),
      expiryYear: (expiry[1] || '').trim(),
      cvv: digits(document.getElementById('cvv').value),
    };

    try {
      const response = await fetch(payUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await response.json().catch(function () { return {}; });

      if (response.ok && data.redirectUrl) {
        window.location.href = data.redirectUrl;
        return;
      }

      if (response.ok && data.success) {
        showMessage(data.message || 'تم الدفع بنجاح.', true);
        if (successUrl) {
          setTimeout(function () { window.location.href = successUrl; }, 1200);
        }
        return;
      }

      showMessage(data.message || 'تعذر إتمام الدفع. تحقق من بيانات البطاقة.', false);
      if (failureUrl && data.terminalFailure) {
        setTimeout(function () { window.location.href = failureUrl; }, 1800);
      }
    } catch (error) {
      showMessage('خطأ في الاتصال. تأكد أن الهاتف على نفس شبكة الـ Wi‑Fi مع السيرفر.', false);
    } finally {
      submitBtn.disabled = false;
    }
  });
})();`;
}

export interface PaymobHostedCheckoutView {
  sessionId: string;
  amountLabel: string;
  currency: string;
  planLabel: string;
  payUrl: string;
  scriptUrl: string;
  appSuccessUrl: string;
  appFailureUrl: string;
}

export function renderPaymobHostedCheckoutPage(view: PaymobHostedCheckoutView): string {
  const title = 'Zakerly Premium';
  const amount = `${view.amountLabel} ${view.currency}`;

  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>${title}</title>
  <style>
    :root { color-scheme: light; --brand: #6C5CE7; --ok: #00B894; --err: #E17055; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: linear-gradient(180deg, #f7f8ff 0%, #ffffff 40%);
      color: #1f2937;
      min-height: 100vh;
    }
    .wrap { max-width: 420px; margin: 0 auto; padding: 24px 16px 40px; }
    .card {
      background: #fff;
      border-radius: 16px;
      box-shadow: 0 8px 30px rgba(108, 92, 231, 0.12);
      padding: 20px;
    }
    h1 { font-size: 1.35rem; margin: 0 0 6px; }
    .sub { color: #6b7280; margin: 0 0 18px; font-size: 0.95rem; }
    .price { font-size: 1.5rem; font-weight: 700; color: var(--brand); margin-bottom: 18px; }
    label { display: block; font-size: 0.85rem; margin: 12px 0 6px; color: #374151; }
    input {
      width: 100%;
      border: 1px solid #d1d5db;
      border-radius: 10px;
      padding: 12px 14px;
      font-size: 1rem;
    }
    input:focus { outline: 2px solid rgba(108, 92, 231, 0.25); border-color: var(--brand); }
    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    button {
      margin-top: 18px;
      width: 100%;
      border: 0;
      border-radius: 12px;
      padding: 14px 16px;
      font-size: 1rem;
      font-weight: 700;
      color: #fff;
      background: var(--brand);
      cursor: pointer;
    }
    button:disabled { opacity: 0.65; cursor: wait; }
    .msg { margin-top: 14px; font-size: 0.92rem; line-height: 1.5; }
    .msg.err { color: var(--err); }
    .msg.ok { color: var(--ok); }
    .hint { margin-top: 16px; font-size: 0.82rem; color: #6b7280; line-height: 1.45; }
    .secure { margin-top: 10px; font-size: 0.8rem; color: #9ca3af; text-align: center; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>${title}</h1>
      <p class="sub">${view.planLabel}</p>
      <div class="price">${amount}</div>
      <form id="pay-form">
        <label for="name">اسم حامل البطاقة</label>
        <input id="name" name="name" autocomplete="cc-name" required maxlength="64" placeholder="Mohamed Ali"/>
        <label for="number">رقم البطاقة</label>
        <input id="number" name="number" inputmode="numeric" autocomplete="cc-number" required maxlength="19" placeholder="4111 1111 1111 1111"/>
        <div class="row">
          <div>
            <label for="expiry">تاريخ الانتهاء</label>
            <input id="expiry" name="expiry" inputmode="numeric" autocomplete="cc-exp" required maxlength="5" placeholder="MM/YY"/>
          </div>
          <div>
            <label for="cvv">CVV</label>
            <input id="cvv" name="cvv" inputmode="numeric" autocomplete="cc-csc" required maxlength="4" placeholder="123"/>
          </div>
        </div>
        <button type="submit" id="submit">ادفع الآن</button>
        <div id="message" class="msg" hidden></div>
      </form>
      <p class="hint">بعد الدفع ارجع للتطبيق واضغط Refresh في صفحة Premium.</p>
      <p class="secure">Secured by Paymob</p>
    </div>
  </div>
  <script src="${view.scriptUrl}" defer></script>
</body>
</html>`;
}

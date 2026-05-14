import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<200'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  const payload = JSON.stringify({
    email: `loadtest-${__VU}@test.com`,
    password: 'Password123!',
    name: `Load Tester ${__VU}`,
  });

  const res = http.post(`${BASE_URL}/v1/auth/register`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'register status is 201': (r) => r.status === 201,
    'has access token': (r) => r.json('tokens.accessToken') !== undefined,
  });

  sleep(1);
}

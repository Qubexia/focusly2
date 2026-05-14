import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '60s',
  thresholds: {
    http_req_duration: ['p(95)<1000'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const TOKEN = __ENV.TOKEN || '';

const endpoints = [
  '/v1/users/me',
  '/v1/subjects',
  '/v1/pomodoro/today',
  '/v1/notifications',
];

export default function () {
  const idx = Math.floor(Math.random() * endpoints.length);
  const url = `${BASE_URL}${endpoints[idx]}`;

  const res = http.get(url, {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
    },
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 1000ms': (r) => r.timings.duration < 1000,
  });

  sleep(0.5);
}

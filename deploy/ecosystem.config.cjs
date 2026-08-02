/** PM2 process manager — Zakerly production */
module.exports = {
  apps: [
    {
      name: 'focaly-api',
      cwd: '/var/opt/focusly2/focaly-backend',
      script: 'dist/main.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
      },
    },
    {
      name: 'focaly-worker',
      cwd: '/var/opt/focusly2/focaly-backend',
      script: 'dist/worker.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
};

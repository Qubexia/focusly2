import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { UsersRepository } from '../src/modules/users/users.repository';

/**
 * Promote (or demote) a user to the admin role so they can sign in to the
 * admin dashboard.
 *
 *   npm run promote-admin -- user@example.com
 *   npm run promote-admin -- user@example.com --demote
 */
async function main(): Promise<void> {
  const email = process.argv[2];
  const demote = process.argv.includes('--demote');

  if (!email || email.startsWith('--')) {
    console.error('Usage: npm run promote-admin -- <email> [--demote]');
    process.exitCode = 1;
    return;
  }

  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const users = app.get(UsersRepository);
    const user = await users.findActiveByEmail(email);

    if (!user) {
      console.error(`No active user found with email "${email}".`);
      process.exitCode = 1;
      return;
    }

    const role = demote ? 'user' : 'admin';
    await users.updateById(String(user._id), { $set: { role } });
    console.log(`✓ ${email} now has role "${role}".`);
  } finally {
    await app.close();
  }
}

void main();

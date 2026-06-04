import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { UsersRepository } from '../src/modules/users/users.repository';

/**
 * Mark a user's email as verified (dev/admin helper).
 *
 *   npm run verify-email -- user@example.com
 */
async function main(): Promise<void> {
  const email = process.argv[2];

  if (!email || email.startsWith('--')) {
    console.error('Usage: npm run verify-email -- <email>');
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

    if (user.emailVerified) {
      console.log(`✓ ${email} is already verified.`);
      return;
    }

    await users.updateOne(
      { _id: user._id, isDeleted: false },
      { $set: { emailVerified: true, lastActiveAt: new Date() } },
    );
    console.log(`✓ ${email} is now verified. Log out and back in to refresh your token.`);
  } finally {
    await app.close();
  }
}

void main();

import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { PasswordService } from '../src/modules/auth/password.service';
import { UsersRepository } from '../src/modules/users/users.repository';

/**
 * Create (or update) a local admin user for the dashboard.
 *
 *   npm run ensure-admin
 *   npm run ensure-admin -- admin@focaly.local 'Admin123!'
 */
async function main(): Promise<void> {
  const email = (process.argv[2] ?? 'admin@focaly.local').toLowerCase();
  const password = process.argv[3] ?? 'Admin123!';
  const name = process.argv[4] ?? 'Focaly Admin';

  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const users = app.get(UsersRepository);
    const passwords = app.get(PasswordService);
    const passwordHash = await passwords.hash(password);
    const existing = await users.findActiveByEmail(email);

    if (existing) {
      await users.updateById(String(existing._id), {
        $set: {
          passwordHash,
          role: 'admin',
          emailVerified: true,
          name,
          isBanned: false,
        },
      });
      console.log(`✓ Updated admin: ${email}`);
    } else {
      const created = await users.create({
        email,
        passwordHash,
        name,
        emailVerified: true,
      });
      await users.updateById(String(created._id), { $set: { role: 'admin' } });
      console.log(`✓ Created admin: ${email}`);
    }

    console.log(`  password: ${password}`);
  } finally {
    await app.close();
  }
}

void main();

import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { UsersModule } from '../users/users.module';

import { AuthSessionsRepository } from './auth-sessions.repository';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { GoogleAuthService } from './google-auth.service';
import { JwtService } from './jwt.service';
import { PasswordService } from './password.service';
import { AuditLog, AuditLogSchema } from './schemas/audit-log.schema';
import { AuthSession, AuthSessionSchema } from './schemas/auth-session.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AuthSession.name, schema: AuthSessionSchema },
      { name: AuditLog.name, schema: AuditLogSchema },
    ]),
    forwardRef(() => UsersModule),
  ],
  controllers: [AuthController],
  providers: [AuthService, AuthSessionsRepository, JwtService, PasswordService, GoogleAuthService],
  exports: [AuthService, AuthSessionsRepository, JwtService, PasswordService, GoogleAuthService],
})
export class AuthModule {}

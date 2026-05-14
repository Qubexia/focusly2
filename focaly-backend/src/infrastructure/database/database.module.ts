import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.getOrThrow<string>('db.uri'),
        maxPoolSize: config.get<number>('db.options.maxPoolSize'),
        autoIndex: config.get<boolean>('db.options.autoIndex'),
        retryAttempts: 5,
        retryDelay: 1000,
      }),
    }),
  ],
  exports: [MongooseModule],
})
export class DatabaseModule {}

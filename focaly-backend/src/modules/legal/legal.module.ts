import { Module } from '@nestjs/common';

import { LegalPagesService } from './legal-pages.service';
import { LegalController } from './legal.controller';

@Module({
  controllers: [LegalController],
  providers: [LegalPagesService],
})
export class LegalModule {}

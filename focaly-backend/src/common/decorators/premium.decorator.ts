import { applyDecorators, UseGuards } from '@nestjs/common';

import { PremiumGuard } from '../guards/premium.guard';

export const Premium = (): MethodDecorator & ClassDecorator =>
  applyDecorators(UseGuards(PremiumGuard));

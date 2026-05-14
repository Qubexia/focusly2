import { ApiPropertyOptional, PartialType } from '@nestjs/swagger';

import { CreatePlannedItemDto } from './create-planned-item.dto';

export class UpdatePlannedItemDto extends PartialType(CreatePlannedItemDto) {}

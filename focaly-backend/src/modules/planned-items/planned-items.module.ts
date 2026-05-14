import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { UsersModule } from '../users/users.module';

import {
  ExamsController,
  LecturesController,
  RevisionsController,
  TasksController,
} from './planned-item-controller.factory';
import { PlannedItemsRepository } from './planned-items.repository';
import { PlannedItemsService } from './planned-items.service';
import { PlannedItem, PlannedItemSchema } from './schemas/planned-item.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: PlannedItem.name, schema: PlannedItemSchema }]),
    UsersModule,
  ],
  controllers: [TasksController, RevisionsController, LecturesController, ExamsController],
  providers: [PlannedItemsService, PlannedItemsRepository],
  exports: [PlannedItemsService, PlannedItemsRepository],
})
export class PlannedItemsModule {}

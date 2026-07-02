import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { ScheduleChangedEvent } from '../../../shared/events/schedule-changed.event';
import { StudySchedulesRepository } from '../../study-schedules/study-schedules.repository';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(ScheduleChangedEvent)
export class ScheduleChangedHandler implements IEventHandler<ScheduleChangedEvent> {
  private readonly logger = new Logger(ScheduleChangedHandler.name);

  constructor(
    private readonly scheduler: NotificationSchedulerService,
    private readonly schedulesRepository: StudySchedulesRepository,
  ) {}

  async handle(event: ScheduleChangedEvent): Promise<void> {
    if (event.kind === 'deleted') {
      await this.scheduler.cancelByRef('study_schedule', event.scheduleId);
      this.logger.log(`Cancelled notification jobs for deleted schedule ${event.scheduleId}`);
      return;
    }

    const schedule = await this.schedulesRepository.findById(event.scheduleId);
    if (!schedule || schedule.userId.toString() !== event.userId) {
      this.logger.warn(`Schedule ${event.scheduleId} not found for notification sync`);
      return;
    }

    await this.scheduler.syncScheduleReminder({
      userId: event.userId,
      id: event.scheduleId,
      title: schedule.title,
      startAt: schedule.startAt,
      reminderMinutesBefore: schedule.reminderMinutesBefore,
      reminderEnabled: schedule.reminderEnabled,
      isActive: schedule.isActive,
    });

    this.logger.log(`Synced notification jobs for schedule ${event.scheduleId} (${event.kind})`);
  }
}

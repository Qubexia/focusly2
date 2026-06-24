import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ERROR_CODES } from '../../common/dto/api-response';
import { PomodoroCompletedEvent } from '../../shared/events/pomodoro-completed.event';

import { PomodoroRepository } from './pomodoro.repository';
import { computeFocusStats } from './pomodoro.util';
import {
  PomodoroBreakMode,
  PomodoroSessionDocument,
  PomodoroStatus,
} from './schemas/pomodoro-session.schema';

@Injectable()
export class PomodoroService {
  constructor(
    private readonly repository: PomodoroRepository,
    private readonly eventBus: EventBus,
  ) {}

  async start(
    userId: string,
    subjectId: string | undefined,
    focusMinutes: number,
    breakMinutes: number,
    sessionMinutes: number,
    breakMode: PomodoroBreakMode = 'cycles',
  ) {
    const active = await this.repository.findActiveByUser(userId);
    if (active) {
      throw new ConflictException({
        code: ERROR_CODES.POMODORO_ALREADY_ACTIVE,
        message: 'Complete or abort the active session first.',
      });
    }

    const now = new Date();
    return this.repository.create({
      userId,
      subjectId: subjectId ?? null,
      focusMinutes,
      breakMinutes,
      sessionMinutes,
      breakMode,
      status: 'active',
      startedAt: now,
      lastTickAt: now,
    });
  }

  async pause(userId: string, sessionId: string) {
    return this.transition(userId, sessionId, 'active', 'paused');
  }

  async resume(userId: string, sessionId: string) {
    return this.transition(userId, sessionId, 'paused', 'active');
  }

  async complete(userId: string, sessionId: string) {
    const session = await this.getOwnedSession(userId, sessionId);
    if (session.status !== 'active' && session.status !== 'paused') {
      throw new ForbiddenException({
        code: ERROR_CODES.FORBIDDEN,
        message: `Cannot complete a session that is ${session.status}.`,
      });
    }

    const now = new Date();
    const { totalFocusMinutes, completedCycles } = computeFocusStats({
      focusMinutes: session.focusMinutes,
      breakMinutes: session.breakMinutes,
      sessionMinutes: session.sessionMinutes,
      breakMode: session.breakMode,
      elapsedMs: now.getTime() - session.startedAt.getTime(),
    });
    const updated = await this.repository.updateStatus(sessionId, 'completed', {
      endedAt: now,
      totalFocusMinutes,
      completedCycles,
    });

    this.eventBus.publish(
      new PomodoroCompletedEvent(
        userId,
        sessionId,
        session.subjectId,
        now,
        session.focusMinutes,
        completedCycles,
        totalFocusMinutes,
      ),
    );

    return updated;
  }

  async abort(userId: string, sessionId: string) {
    const session = await this.getOwnedSession(userId, sessionId);
    if (session.status === 'completed' || session.status === 'aborted') {
      throw new ForbiddenException({
        code: ERROR_CODES.FORBIDDEN,
        message: `Cannot abort a session that is already ${session.status}.`,
      });
    }

    const now = new Date();
    const { totalFocusMinutes, completedCycles } = computeFocusStats({
      focusMinutes: session.focusMinutes,
      breakMinutes: session.breakMinutes,
      sessionMinutes: session.sessionMinutes,
      breakMode: session.breakMode,
      elapsedMs: now.getTime() - session.startedAt.getTime(),
    });

    return this.repository.updateStatus(sessionId, 'aborted', {
      endedAt: now,
      totalFocusMinutes,
      completedCycles,
    });
  }

  async today(userId: string) {
    const now = new Date();
    const startOfDay = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
    const endOfDay = new Date(startOfDay.getTime() + 86_400_000);

    const sessions = await this.repository.findTodayByUser(userId, startOfDay, endOfDay);
    const activeSession = await this.repository.findActiveByUser(userId);
    const totalFocusMinutes = sessions.reduce((sum, s) => sum + (s.totalFocusMinutes || 0), 0);

    return { sessions, totalFocusMinutes, activeSession };
  }

  async history(userId: string, from: string, to: string, cursor?: string, limit = 20) {
    const sessions = await this.repository.findHistory(
      userId,
      new Date(from),
      new Date(to),
      limit,
      cursor,
    );
    const last = sessions[sessions.length - 1];
    const nextCursor: string | null = last ? String(last._id) : null;
    return { data: sessions, nextCursor };
  }

  private async getOwnedSession(
    userId: string,
    sessionId: string,
  ): Promise<PomodoroSessionDocument> {
    const session = await this.repository.findById(sessionId);
    if (!session || session.userId.toString() !== userId) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Session was not found.',
      });
    }
    return session;
  }

  private async transition(
    userId: string,
    sessionId: string,
    fromStatus: PomodoroStatus,
    toStatus: PomodoroStatus,
  ) {
    const session = await this.getOwnedSession(userId, sessionId);
    if (session.status !== fromStatus) {
      throw new ForbiddenException({
        code: ERROR_CODES.FORBIDDEN,
        message: `Cannot transition from ${session.status} to ${toStatus}.`,
      });
    }

    return this.repository.updateStatus(sessionId, toStatus);
  }
}

import 'dart:math';

/// A snapshot of where a session sits on its repeating focus/break timeline,
/// derived purely from how many seconds of active time have elapsed.
class PomodoroTick {
  const PomodoroTick({
    required this.isDone,
    required this.isBreak,
    required this.remainingSeconds,
    required this.phaseTotalSeconds,
    required this.sessionElapsedSeconds,
    required this.sessionTotalSeconds,
    required this.focusElapsedSeconds,
  });

  /// The whole session has finished (elapsed reached the planned length).
  final bool isDone;

  /// The current phase is a break (otherwise it is a focus block).
  final bool isBreak;

  /// Seconds remaining in the current phase.
  final int remainingSeconds;

  /// Length of the current phase in seconds (used for the progress ring).
  final int phaseTotalSeconds;

  /// Active seconds elapsed across the whole session.
  final int sessionElapsedSeconds;

  /// Planned total length of the session in seconds.
  final int sessionTotalSeconds;

  /// Total seconds actually spent in focus blocks so far.
  final int focusElapsedSeconds;
}

/// The two ways a session lays out its break(s).
///
/// - `cycles`: repeats `focus → break` until the session length is reached.
/// - `middle`: a single break placed in the middle of the study time, i.e.
///   `focus → break → focus`, where the total length is [sessionMinutes].
const pomodoroBreakModeCycles = 'cycles';
const pomodoroBreakModeMiddle = 'middle';

/// Computes the current phase of a session.
///
/// In the default `cycles` mode the session repeats `focus → break` until
/// `sessionMinutes` elapse. In `middle` mode there is one break in the middle of
/// the study time. The final block is truncated so the session never runs past
/// its planned length.
PomodoroTick computePomodoroTick({
  required int elapsedSeconds,
  required int focusMinutes,
  required int breakMinutes,
  required int sessionMinutes,
  String breakMode = pomodoroBreakModeCycles,
}) {
  if (breakMode == pomodoroBreakModeMiddle) {
    return _computeMiddleBreakTick(
      elapsedSeconds: elapsedSeconds,
      breakMinutes: breakMinutes,
      sessionMinutes: sessionMinutes,
    );
  }

  final focusSec = focusMinutes * 60;
  final breakSec = breakMinutes * 60;
  final sessionSec = max(sessionMinutes * 60, focusSec);
  final cycleSec = focusSec + breakSec;

  final elapsed = elapsedSeconds.clamp(0, sessionSec);

  // Total focus seconds accrued so far (capped at the session length).
  final int focusElapsed;
  if (cycleSec <= 0 || focusSec <= 0) {
    focusElapsed = elapsed;
  } else {
    final fullCycles = elapsed ~/ cycleSec;
    final remainder = elapsed - fullCycles * cycleSec;
    focusElapsed = fullCycles * focusSec + min(remainder, focusSec);
  }

  if (elapsed >= sessionSec) {
    return PomodoroTick(
      isDone: true,
      isBreak: false,
      remainingSeconds: 0,
      phaseTotalSeconds: focusSec,
      sessionElapsedSeconds: sessionSec,
      sessionTotalSeconds: sessionSec,
      focusElapsedSeconds: focusElapsed,
    );
  }

  // No break configured → one continuous focus block until the session ends.
  if (cycleSec <= 0 || breakSec <= 0) {
    return PomodoroTick(
      isDone: false,
      isBreak: false,
      remainingSeconds: sessionSec - elapsed,
      phaseTotalSeconds: sessionSec,
      sessionElapsedSeconds: elapsed,
      sessionTotalSeconds: sessionSec,
      focusElapsedSeconds: focusElapsed,
    );
  }

  final cycleStart = (elapsed ~/ cycleSec) * cycleSec;
  final posInCycle = elapsed - cycleStart;

  final int phaseStart;
  final int phaseEnd;
  final bool isBreak;
  if (posInCycle < focusSec) {
    phaseStart = cycleStart;
    phaseEnd = min(cycleStart + focusSec, sessionSec);
    isBreak = false;
  } else {
    phaseStart = cycleStart + focusSec;
    phaseEnd = min(cycleStart + cycleSec, sessionSec);
    isBreak = true;
  }

  return PomodoroTick(
    isDone: false,
    isBreak: isBreak,
    remainingSeconds: phaseEnd - elapsed,
    phaseTotalSeconds: phaseEnd - phaseStart,
    sessionElapsedSeconds: elapsed,
    sessionTotalSeconds: sessionSec,
    focusElapsedSeconds: focusElapsed,
  );
}

/// A single break placed in the middle of the study time: `focus → break →
/// focus`. [sessionMinutes] is the whole length (study + break); the break is
/// [breakMinutes] long and the remaining time is split into two focus blocks.
PomodoroTick _computeMiddleBreakTick({
  required int elapsedSeconds,
  required int breakMinutes,
  required int sessionMinutes,
}) {
  final sessionSec = max(sessionMinutes * 60, 1);
  final breakSec = (breakMinutes * 60).clamp(0, sessionSec - 1);
  final studySec = max(sessionSec - breakSec, 0);
  final firstFocusSec = studySec ~/ 2; // break starts after the first half
  final breakStart = firstFocusSec;
  final breakEnd = firstFocusSec + breakSec;

  final elapsed = elapsedSeconds.clamp(0, sessionSec);

  // Focus time accrued so far = elapsed minus whatever break time has passed.
  final int focusElapsed;
  if (elapsed <= breakStart) {
    focusElapsed = elapsed;
  } else if (elapsed < breakEnd) {
    focusElapsed = breakStart;
  } else {
    focusElapsed = elapsed - breakSec;
  }

  if (elapsed >= sessionSec) {
    return PomodoroTick(
      isDone: true,
      isBreak: false,
      remainingSeconds: 0,
      phaseTotalSeconds: max(sessionSec - breakEnd, 1),
      sessionElapsedSeconds: sessionSec,
      sessionTotalSeconds: sessionSec,
      focusElapsedSeconds: studySec,
    );
  }

  // No break → one continuous focus block.
  if (breakSec <= 0) {
    return PomodoroTick(
      isDone: false,
      isBreak: false,
      remainingSeconds: sessionSec - elapsed,
      phaseTotalSeconds: sessionSec,
      sessionElapsedSeconds: elapsed,
      sessionTotalSeconds: sessionSec,
      focusElapsedSeconds: elapsed,
    );
  }

  final int phaseStart;
  final int phaseEnd;
  final bool isBreak;
  if (elapsed < breakStart) {
    phaseStart = 0;
    phaseEnd = breakStart;
    isBreak = false;
  } else if (elapsed < breakEnd) {
    phaseStart = breakStart;
    phaseEnd = breakEnd;
    isBreak = true;
  } else {
    phaseStart = breakEnd;
    phaseEnd = sessionSec;
    isBreak = false;
  }

  return PomodoroTick(
    isDone: false,
    isBreak: isBreak,
    remainingSeconds: phaseEnd - elapsed,
    phaseTotalSeconds: max(phaseEnd - phaseStart, 1),
    sessionElapsedSeconds: elapsed,
    sessionTotalSeconds: sessionSec,
    focusElapsedSeconds: focusElapsed,
  );
}

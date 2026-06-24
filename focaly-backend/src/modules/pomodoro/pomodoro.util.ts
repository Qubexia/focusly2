export interface PomodoroFocusStats {
  /** Minutes actually spent studying (sum of focus blocks within the elapsed window). */
  totalFocusMinutes: number;
  /** Number of focus blocks fully completed. */
  completedCycles: number;
}

export interface ComputeFocusStatsInput {
  focusMinutes: number;
  breakMinutes: number;
  /** Total planned session length; elapsed time is capped at this. */
  sessionMinutes: number;
  /** How breaks are laid out. Defaults to repeating cycles. */
  breakMode?: 'cycles' | 'middle';
  /** Wall-clock time elapsed since the session started, in milliseconds. */
  elapsedMs: number;
}

const MS_PER_MINUTE = 60_000;

/**
 * A session repeats focus/break cycles until `sessionMinutes` elapses. Given how
 * long the session actually ran, this returns the studied minutes (sum of focus
 * blocks that fall inside the elapsed window, capped at the planned session
 * length) and how many focus blocks were fully completed.
 */
export function computeFocusStats(input: ComputeFocusStatsInput): PomodoroFocusStats {
  const { focusMinutes, breakMinutes } = input;
  const sessionMinutes =
    input.sessionMinutes > 0 ? input.sessionMinutes : focusMinutes + breakMinutes;
  const elapsedMin = Math.min(Math.max(input.elapsedMs, 0) / MS_PER_MINUTE, sessionMinutes);

  if (input.breakMode === 'middle') {
    return computeMiddleBreakStats(sessionMinutes, breakMinutes, elapsedMin);
  }

  const cycleMinutes = focusMinutes + breakMinutes;
  if (focusMinutes <= 0 || cycleMinutes <= 0) {
    return { totalFocusMinutes: Math.round(elapsedMin), completedCycles: 0 };
  }

  const fullCycles = Math.floor(elapsedMin / cycleMinutes);
  const remainder = elapsedMin - fullCycles * cycleMinutes;
  const focusInRemainder = Math.min(remainder, focusMinutes);
  const totalFocusMinutes = Math.round(fullCycles * focusMinutes + focusInRemainder);

  const completedCycles =
    elapsedMin >= focusMinutes ? Math.floor((elapsedMin - focusMinutes) / cycleMinutes) + 1 : 0;

  return { totalFocusMinutes, completedCycles };
}

/**
 * A `middle`-mode session runs `focus → break → focus`, with one break in the
 * middle of the study time. Studied minutes are the elapsed time minus the part
 * of the break that has passed; a focus block counts as completed when the
 * first half finishes and again when the whole session finishes.
 */
function computeMiddleBreakStats(
  sessionMinutes: number,
  breakMinutes: number,
  elapsedMin: number,
): PomodoroFocusStats {
  const breakMin = Math.min(Math.max(breakMinutes, 0), Math.max(sessionMinutes - 1, 0));
  const studyMin = Math.max(sessionMinutes - breakMin, 0);
  const firstFocus = studyMin / 2; // break begins after the first half
  const breakEnd = firstFocus + breakMin;

  let focus: number;
  if (elapsedMin <= firstFocus) {
    focus = elapsedMin;
  } else if (elapsedMin < breakEnd) {
    focus = firstFocus;
  } else {
    focus = elapsedMin - breakMin;
  }

  const completedCycles =
    (elapsedMin >= firstFocus ? 1 : 0) + (elapsedMin >= sessionMinutes ? 1 : 0);

  return { totalFocusMinutes: Math.round(focus), completedCycles };
}

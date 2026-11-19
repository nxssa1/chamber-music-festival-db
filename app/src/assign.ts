/**
 * Greedy ensemble assignment algorithm.
 *
 * Given all active participants and all available works, produces a list of
 * (work, members[]) assignments that satisfy:
 *   1. Instrumentation — every required seat is filled with the right instrument
 *   2. Ability spread ≤ MAX_SPREAD (default 4)
 *   3. No avoidance conflicts (checked against Neo4j)
 *   4. No participant assigned twice
 *
 * This module contains the pure combinatorial logic.
 * The API route /api/schedule/run wraps it in a PostgreSQL transaction,
 * persists the result, and validates with fn_check_instrumentation().
 */

export const MAX_SPREAD = 4;

export interface Participant {
  participant_id: number;
  primary_instrument: number;
  skill_grade: number;
}

export interface WorkSeat {
  instrument_id: number;
  players_required: number;
}

export interface Work {
  work_id: number;
  seats: WorkSeat[];
}

export interface Assignment {
  work_id: number;
  members: { participant_id: number; instrument_id: number }[];
  ability_spread: number;
}

/**
 * Try to form one ensemble for `work` using players from `pool`.
 * Returns the assignment and the remaining pool, or null if impossible.
 */
function tryFormEnsemble(
  work: Work,
  pool: Participant[],
  avoidance: Set<string>
): { assignment: Assignment; remaining: Participant[] } | null {
  // Build candidates per seat
  const seatCandidates: Participant[][] = work.seats.flatMap((seat) =>
    Array.from({ length: seat.players_required }, () =>
      pool.filter((p) => p.primary_instrument === seat.instrument_id)
    )
  );

  if (seatCandidates.some((c) => c.length === 0)) return null;

  // Greedy: pick the first candidate for each seat that doesn't violate spread or avoidance
  const chosen: Participant[] = [];

  for (const candidates of seatCandidates) {
    let picked: Participant | null = null;
    for (const candidate of candidates) {
      if (chosen.includes(candidate)) continue;

      // Check avoidance against already-chosen members
      const conflict = chosen.some((m) => {
        const key = `${Math.min(m.participant_id, candidate.participant_id)}-${Math.max(m.participant_id, candidate.participant_id)}`;
        return avoidance.has(key);
      });
      if (conflict) continue;

      // Check spread
      const grades = [...chosen.map((m) => m.skill_grade), candidate.skill_grade];
      if (Math.max(...grades) - Math.min(...grades) > MAX_SPREAD) continue;

      picked = candidate;
      break;
    }
    if (!picked) return null;
    chosen.push(picked);
  }

  const grades = chosen.map((m) => m.skill_grade);
  const spread = Math.max(...grades) - Math.min(...grades);
  const chosenIds = new Set(chosen.map((p) => p.participant_id));

  const assignment: Assignment = {
    work_id: work.work_id,
    members: chosen.map((p) => ({ participant_id: p.participant_id, instrument_id: p.primary_instrument })),
    ability_spread: spread,
  };

  return {
    assignment,
    remaining: pool.filter((p) => !chosenIds.has(p.participant_id)),
  };
}

/**
 * Run the greedy algorithm across all works.
 * Returns assignments and any participants who could not be placed.
 */
export function greedyAssign(
  participants: Participant[],
  works: Work[],
  avoidance: Set<string>
): { assignments: Assignment[]; unplaced: Participant[] } {
  let pool = [...participants];
  const assignments: Assignment[] = [];

  for (const work of works) {
    const result = tryFormEnsemble(work, pool, avoidance);
    if (result) {
      assignments.push(result.assignment);
      pool = result.remaining;
    }
  }

  return { assignments, unplaced: pool };
}

// Neo4j driver — Bolt connection
import neo4j from 'neo4j-driver';

const driver = neo4j.driver(
  process.env.NEO4J_URI!,
  neo4j.auth.basic(process.env.NEO4J_USER!, process.env.NEO4J_PASSWORD!)
);

export default driver;

/**
 * Check whether placing two participants together violates an avoidance constraint.
 * Returns true if the pair is incompatible (should NOT be in the same ensemble).
 */
export async function hasAvoidanceConflict(p1: number, p2: number): Promise<boolean> {
  const session = driver.session();
  try {
    const result = await session.run(
      `MATCH (a:Person {id: $p1})-[:AVOIDS]->(b:Person {id: $p2})
       RETURN count(b) AS conflicts`,
      { p1, p2 }
    );
    const conflicts = result.records[0]?.get('conflicts').toNumber() ?? 0;
    return conflicts > 0;
  } finally {
    await session.close();
  }
}

/**
 * Fetch all avoidance pairs for a list of participant IDs in one query.
 * Returns a Set of "smallerId-largerId" strings for O(1) lookup.
 */
export async function getAvoidanceSet(participantIds: number[]): Promise<Set<string>> {
  const session = driver.session();
  try {
    const result = await session.run(
      `MATCH (a:Person)-[:AVOIDS]->(b:Person)
       WHERE a.id IN $ids AND b.id IN $ids
       RETURN a.id AS from, b.id AS to`,
      { ids: participantIds }
    );
    const set = new Set<string>();
    for (const rec of result.records) {
      const f = rec.get('from').toNumber();
      const t = rec.get('to').toNumber();
      set.add(`${Math.min(f, t)}-${Math.max(f, t)}`);
    }
    return set;
  } finally {
    await session.close();
  }
}

// Neo4j seed — Chamber Music Festival social graph
// Run against a fresh Neo4j 5 database:
//   cypher-shell -f neo4j/seed.cypher

// ── Constraints ────────────────────────────────────────────────────────────────
CREATE CONSTRAINT person_id IF NOT EXISTS
  FOR (p:Person) REQUIRE p.id IS UNIQUE;

// ── Person nodes (mirror participant.participant_id) ───────────────────────────
MERGE (:Person {id: 1, name: 'Alice Chen'});
MERGE (:Person {id: 2, name: 'Bob Mukherjee'});
MERGE (:Person {id: 3, name: 'Carol Nair'});
MERGE (:Person {id: 4, name: 'Daniel Osei'});
MERGE (:Person {id: 5, name: 'Eva Russo'});

// ── Avoidance edges ────────────────────────────────────────────────────────────
// AVOIDS means: "do not place me in the same ensemble as this person"
MATCH (a:Person {id: 2}), (b:Person {id: 4})
MERGE (a)-[:AVOIDS]->(b);

// ── Pairing wishes ─────────────────────────────────────────────────────────────
// WANTS_WITH means: "I would prefer to be in the same ensemble as this person"
MATCH (a:Person {id: 1}), (b:Person {id: 3})
MERGE (a)-[:WANTS_WITH]->(b);

MATCH (a:Person {id: 4}), (b:Person {id: 5})
MERGE (a)-[:WANTS_WITH]->(b);

// ── Prior collaboration edges ──────────────────────────────────────────────────
// PLAYED_WITH means: previously appeared in the same ensemble (informational)
MATCH (a:Person {id: 1}), (b:Person {id: 5})
MERGE (a)-[:PLAYED_WITH {year: 2025}]->(b);

// ── Avoidance-conflict check query (used by the assignment algorithm) ──────────
// Returns > 0 if placing p1 and p2 together violates an avoidance constraint:
//
// MATCH (a:Person {id: $p1})-[:AVOIDS]->(b:Person {id: $p2})
// RETURN count(b) AS conflicts

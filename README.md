# Chamber Music Festival — Ensemble Formation & Rehearsal Scheduling System

**Course:** UE24CS351A – DBMS Project, Semester AUG–DEC 2026, PES University  
**Team:** Naveen Karthikeyan (PES2UG24CS306) · Partner (PES2UG24CS250)  
**Guide:** Dr. Shilpa S, Assistant Professor, Dept. of CSE

---

## Problem Statement

Automate the formation of chamber music ensembles and the scheduling of their rehearsals for a multi-day festival. Given a roster of musicians with varying instruments, grades, and social preferences, the system partitions them into groups that satisfy:

- **Instrumentation constraints** – every required instrument seat in a work must be filled (e.g. Schubert D 956 needs exactly 2 violins, 1 viola, 2 cellos)
- **Ability-spread constraint** – MAX(grade) − MIN(grade) ≤ 4 within each ensemble
- **Room / time-slot conflict constraint** – no two ensembles share a room in the same slot; no coach or participant double-booked
- **Repertoire-history constraint** – participants are not assigned a work they played in a prior festival year
- **Social compatibility** – avoidance and pairing wishes stored as a Neo4j graph are checked before accepting any candidate assignment

---

## Tech Stack

| Layer | Technology |
|---|---|
| Primary DB | PostgreSQL 16 + `btree_gist` extension |
| Graph DB | Neo4j 5 (Bolt) |
| Backend / Frontend | Next.js 14 App Router + TypeScript |
| DB client (SQL) | postgres.js (raw parameterised SQL, no ORM) |
| DB client (Graph) | neo4j-driver |
| Auth | next-auth v5, bcrypt, role-based JWT |

---

## Repository Layout

```
chamber-music-festival-db/
├── sql/
│   ├── 01_schema.sql          # CREATE TABLE for all 12 relations
│   ├── 02_alter_index_view.sql # ALTER, 5 indexes, 3 views
│   └── 03_teardown.sql        # DROP in reverse dependency order
├── neo4j/
│   └── seed.cypher            # Person nodes + relationship edges
├── app/
│   └── src/                   # Next.js application source
└── docs/
    ├── PES2UG24CS306_PES2UG24CS250_Report.docx
    └── er_diagram.png
```

---

## Database Schema (12 tables)

`instrument` · `participant` · `work` · `work_instrumentation` · `coach` · `room` · `time_slot` · `schedule_run` · `ensemble` · `ensemble_member` · `repertoire_history` · `preference`

### Key advanced features

| Feature | Implementation |
|---|---|
| Trigger 1 | `trg_recompute_spread` – auto-recomputes `ability_spread` on member insert/delete |
| Trigger 2 | `trg_lock_published` – raises exception on mutation of a published schedule |
| Stored function | `fn_check_instrumentation()` – validates seat fill per ensemble |
| Recursive CTE | Blast-radius query – finds all ensembles affected by a withdrawal |
| Transaction | Atomic schedule-run creation with rollback on instrumentation failure |
| Views (×3) | `v_participant_schedule`, `v_coach_load`, `v_instrument_demand` |
| Partial indexes (×5) | Optimise active-participant queries and slot conflict lookups |

---

## Setup

### PostgreSQL

```bash
createdb festival_db
psql festival_db -f sql/01_schema.sql
psql festival_db -f sql/02_alter_index_view.sql
```

### Neo4j

```bash
# Start Neo4j, then:
cypher-shell -f neo4j/seed.cypher
```

### Next.js app

```bash
cd app
cp .env.example .env.local   # fill DATABASE_URL, NEO4J_URI, NEXTAUTH_SECRET
npm install
npm run dev
```

---

## Teardown

```bash
psql festival_db -f sql/03_teardown.sql
dropdb festival_db
```

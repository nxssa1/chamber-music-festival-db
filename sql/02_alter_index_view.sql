-- ALTER statements
ALTER TABLE participant ADD COLUMN withdrawn_on DATE;
ALTER TABLE participant ADD CONSTRAINT chk_withdrawal
    CHECK (withdrawn_on IS NULL OR withdrawn_on >= registered_on);
ALTER TABLE ensemble ADD COLUMN is_manual_override BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE work ALTER COLUMN key_signature TYPE VARCHAR(50);

-- Indexes
CREATE INDEX idx_participant_instrument_grade
    ON participant (primary_instrument, skill_grade) WHERE is_active = TRUE;
CREATE INDEX idx_rep_hist_participant ON repertoire_history (participant_id, work_id);
CREATE INDEX idx_ensemble_slot ON ensemble (slot_id, schedule_run_id);
CREATE INDEX idx_member_participant ON ensemble_member (participant_id);
CREATE INDEX idx_work_type_difficulty ON work (ensemble_type, difficulty_grade);

-- Views
CREATE VIEW v_participant_schedule AS
SELECT p.participant_id, p.full_name, ts.festival_day, ts.start_time, ts.end_time,
       r.room_name, w.title AS work_title, w.composer, c.full_name AS coach_name
FROM   participant p
JOIN   ensemble_member em ON em.participant_id = p.participant_id
JOIN   ensemble e        ON e.ensemble_id      = em.ensemble_id
JOIN   schedule_run sr   ON sr.run_id          = e.schedule_run_id
JOIN   time_slot ts      ON ts.slot_id         = e.slot_id
JOIN   room r            ON r.room_id          = e.room_id
JOIN   work w            ON w.work_id          = e.work_id
JOIN   coach c           ON c.coach_id         = e.coach_id
WHERE  sr.status = 'published';

CREATE VIEW v_coach_load AS
SELECT c.coach_id, c.full_name, c.max_ensembles,
       COUNT(e.ensemble_id) AS assigned_ensembles,
       c.max_ensembles - COUNT(e.ensemble_id) AS remaining_capacity
FROM   coach c
LEFT JOIN ensemble e     ON e.coach_id = c.coach_id
LEFT JOIN schedule_run sr ON sr.run_id = e.schedule_run_id AND sr.status = 'published'
GROUP BY c.coach_id, c.full_name, c.max_ensembles;

CREATE VIEW v_instrument_demand AS
SELECT i.instrument_name,
       COALESCE(SUM(wi.players_required), 0) AS total_seats_required,
       (SELECT COUNT(*) FROM participant p
        WHERE p.primary_instrument = i.instrument_id AND p.is_active = TRUE) AS available_players
FROM   instrument i
LEFT JOIN work_instrumentation wi ON wi.instrument_id = i.instrument_id
GROUP BY i.instrument_id, i.instrument_name;

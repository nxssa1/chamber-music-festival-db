-- Teardown, dependency-ordered
DROP VIEW  IF EXISTS v_instrument_demand;
DROP VIEW  IF EXISTS v_coach_load;
DROP VIEW  IF EXISTS v_participant_schedule;

DROP TABLE IF EXISTS preference;
DROP TABLE IF EXISTS repertoire_history;
DROP TABLE IF EXISTS ensemble_member;
DROP TABLE IF EXISTS ensemble;
DROP TABLE IF EXISTS schedule_run;
DROP TABLE IF EXISTS time_slot;
DROP TABLE IF EXISTS room;
DROP TABLE IF EXISTS coach;
DROP TABLE IF EXISTS work_instrumentation;
DROP TABLE IF EXISTS work;
DROP TABLE IF EXISTS participant;
DROP TABLE IF EXISTS instrument;

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE instrument (
    instrument_id    SERIAL PRIMARY KEY,
    instrument_name  VARCHAR(50)  NOT NULL UNIQUE,
    family           VARCHAR(30)  NOT NULL,
    clef             VARCHAR(20)  NOT NULL,
    CONSTRAINT chk_family CHECK (
        family IN ('strings', 'woodwind', 'brass', 'keyboard', 'percussion')
    )
);

CREATE TABLE participant (
    participant_id     SERIAL PRIMARY KEY,
    full_name          VARCHAR(100) NOT NULL,
    email              VARCHAR(120) NOT NULL UNIQUE,
    password_hash      VARCHAR(255) NOT NULL,
    role               VARCHAR(20)  NOT NULL DEFAULT 'participant',
    primary_instrument INTEGER      NOT NULL,
    skill_grade        SMALLINT     NOT NULL,
    years_playing      SMALLINT     NOT NULL DEFAULT 0,
    registered_on      DATE         NOT NULL DEFAULT CURRENT_DATE,
    is_active          BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_participant_instrument
        FOREIGN KEY (primary_instrument) REFERENCES instrument(instrument_id),
    CONSTRAINT chk_skill_grade  CHECK (skill_grade BETWEEN 1 AND 10),
    CONSTRAINT chk_role         CHECK (role IN ('participant', 'organiser')),
    CONSTRAINT chk_years        CHECK (years_playing >= 0),
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%')
);

CREATE TABLE work (
    work_id          SERIAL PRIMARY KEY,
    title            VARCHAR(200) NOT NULL,
    composer         VARCHAR(100) NOT NULL,
    opus_number      VARCHAR(30),
    key_signature    VARCHAR(30),
    movement_count   SMALLINT     NOT NULL DEFAULT 1,
    duration_minutes SMALLINT     NOT NULL,
    difficulty_grade SMALLINT     NOT NULL,
    ensemble_type    VARCHAR(30)  NOT NULL,
    CONSTRAINT uq_work UNIQUE (title, composer, opus_number),
    CONSTRAINT chk_difficulty CHECK (difficulty_grade BETWEEN 1 AND 10),
    CONSTRAINT chk_duration   CHECK (duration_minutes > 0),
    CONSTRAINT chk_movements  CHECK (movement_count > 0),
    CONSTRAINT chk_ens_type   CHECK (
        ensemble_type IN ('duo','trio','quartet','quintet','sextet')
    )
);

CREATE TABLE work_instrumentation (
    work_id          INTEGER  NOT NULL,
    instrument_id    INTEGER  NOT NULL,
    players_required SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (work_id, instrument_id),
    CONSTRAINT fk_wi_work
        FOREIGN KEY (work_id) REFERENCES work(work_id) ON DELETE CASCADE,
    CONSTRAINT fk_wi_instrument
        FOREIGN KEY (instrument_id) REFERENCES instrument(instrument_id),
    CONSTRAINT chk_players CHECK (players_required > 0)
);

CREATE TABLE coach (
    coach_id                 SERIAL PRIMARY KEY,
    full_name                VARCHAR(100) NOT NULL,
    email                    VARCHAR(120) NOT NULL UNIQUE,
    specialism_instrument_id INTEGER      NOT NULL,
    max_ensembles            SMALLINT     NOT NULL DEFAULT 4,
    CONSTRAINT fk_coach_instrument
        FOREIGN KEY (specialism_instrument_id) REFERENCES instrument(instrument_id),
    CONSTRAINT chk_max_ensembles CHECK (max_ensembles BETWEEN 1 AND 10)
);

CREATE TABLE room (
    room_id   SERIAL PRIMARY KEY,
    room_name VARCHAR(50) NOT NULL UNIQUE,
    capacity  SMALLINT    NOT NULL,
    has_piano BOOLEAN     NOT NULL DEFAULT FALSE,
    building  VARCHAR(50) NOT NULL,
    CONSTRAINT chk_capacity CHECK (capacity > 0)
);

CREATE TABLE time_slot (
    slot_id      SERIAL PRIMARY KEY,
    festival_day DATE NOT NULL,
    start_time   TIME NOT NULL,
    end_time     TIME NOT NULL,
    CONSTRAINT uq_slot UNIQUE (festival_day, start_time),
    CONSTRAINT chk_slot_times CHECK (end_time > start_time)
);

CREATE TABLE schedule_run (
    run_id         SERIAL PRIMARY KEY,
    run_by         INTEGER   NOT NULL,
    run_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quality_score  NUMERIC(6,2),
    status         VARCHAR(20) NOT NULL DEFAULT 'draft',
    unplaced_count SMALLINT    NOT NULL DEFAULT 0,
    CONSTRAINT fk_run_by FOREIGN KEY (run_by) REFERENCES participant(participant_id),
    CONSTRAINT chk_status CHECK (status IN ('draft', 'published', 'superseded')),
    CONSTRAINT chk_unplaced CHECK (unplaced_count >= 0)
);

CREATE TABLE ensemble (
    ensemble_id     SERIAL PRIMARY KEY,
    work_id         INTEGER NOT NULL,
    coach_id        INTEGER NOT NULL,
    room_id         INTEGER NOT NULL,
    slot_id         INTEGER NOT NULL,
    schedule_run_id INTEGER NOT NULL,
    ability_spread  SMALLINT,
    formed_on       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ens_work  FOREIGN KEY (work_id)  REFERENCES work(work_id),
    CONSTRAINT fk_ens_coach FOREIGN KEY (coach_id) REFERENCES coach(coach_id),
    CONSTRAINT fk_ens_room  FOREIGN KEY (room_id)  REFERENCES room(room_id),
    CONSTRAINT fk_ens_slot  FOREIGN KEY (slot_id)  REFERENCES time_slot(slot_id),
    CONSTRAINT fk_ens_run
        FOREIGN KEY (schedule_run_id) REFERENCES schedule_run(run_id) ON DELETE CASCADE,
    CONSTRAINT uq_room_slot  UNIQUE (room_id,  slot_id, schedule_run_id),
    CONSTRAINT uq_coach_slot UNIQUE (coach_id, slot_id, schedule_run_id),
    CONSTRAINT chk_spread CHECK (ability_spread >= 0)
);

CREATE TABLE ensemble_member (
    ensemble_id    INTEGER NOT NULL,
    participant_id INTEGER NOT NULL,
    instrument_id  INTEGER NOT NULL,
    is_substitute  BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ensemble_id, participant_id),
    CONSTRAINT fk_em_ensemble
        FOREIGN KEY (ensemble_id) REFERENCES ensemble(ensemble_id) ON DELETE CASCADE,
    CONSTRAINT fk_em_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id),
    CONSTRAINT fk_em_instrument
        FOREIGN KEY (instrument_id) REFERENCES instrument(instrument_id)
);

CREATE TABLE repertoire_history (
    history_id     SERIAL PRIMARY KEY,
    participant_id INTEGER  NOT NULL,
    work_id        INTEGER  NOT NULL,
    festival_year  SMALLINT NOT NULL,
    CONSTRAINT fk_rh_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE CASCADE,
    CONSTRAINT fk_rh_work FOREIGN KEY (work_id) REFERENCES work(work_id),
    CONSTRAINT uq_rep_hist UNIQUE (participant_id, work_id, festival_year),
    CONSTRAINT chk_year CHECK (festival_year BETWEEN 1990 AND 2100)
);

CREATE TABLE preference (
    preference_id   SERIAL PRIMARY KEY,
    participant_id  INTEGER  NOT NULL,
    work_id         INTEGER  NOT NULL,
    preference_rank SMALLINT NOT NULL,
    CONSTRAINT fk_pref_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE CASCADE,
    CONSTRAINT fk_pref_work FOREIGN KEY (work_id) REFERENCES work(work_id),
    CONSTRAINT uq_pref_rank UNIQUE (participant_id, preference_rank),
    CONSTRAINT chk_rank CHECK (preference_rank BETWEEN 1 AND 5)
);

-- Фінальний проєкт: схема pandemic, нормалізація, аналіз, функції.
-- Файл запускається в psql: psql -d <база> -f final_project.sql (з кореня репозиторію).

-- 1. Схема pandemic
CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic;

-- 1. Вихідна таблиця infectious_cases (усі колонки TEXT)
DROP TABLE IF EXISTS cases;
DROP TABLE IF EXISTS entities;
DROP TABLE IF EXISTS infectious_cases;

CREATE TABLE infectious_cases (
    entity                TEXT,
    code                  TEXT,
    year                  TEXT,
    number_yaws           TEXT,
    polio_cases           TEXT,
    cases_guinea_worm     TEXT,
    number_rabies         TEXT,
    number_malaria        TEXT,
    number_hiv            TEXT,
    number_tuberculosis   TEXT,
    number_smallpox       TEXT,
    number_cholera_cases  TEXT
);

-- 1. Імпорт CSV (команда psql, запускати з кореня репозиторію)
\copy infectious_cases FROM 'data/infectious_cases.csv' WITH (FORMAT csv, HEADER true)

-- 1. Перегляд даних
SELECT *
FROM infectious_cases
ORDER BY entity, year
LIMIT 10;

-- 2. Таблиця entities
CREATE TABLE entities (
    id      SERIAL PRIMARY KEY,
    entity  TEXT NOT NULL UNIQUE,
    code    TEXT
);

INSERT INTO entities (entity, code)
SELECT DISTINCT entity, code
FROM infectious_cases
ORDER BY entity;

-- 2. Таблиця cases
CREATE TABLE cases (
    id                    SERIAL PRIMARY KEY,
    entity_id             INTEGER NOT NULL REFERENCES entities (id),
    year                  INTEGER NOT NULL CHECK (year BETWEEN 1800 AND 2100),
    number_yaws           NUMERIC(18, 6),
    polio_cases           NUMERIC(18, 6),
    cases_guinea_worm     NUMERIC(18, 6),
    number_rabies         NUMERIC(18, 6),
    number_malaria        NUMERIC(18, 6),
    number_hiv            NUMERIC(18, 6),
    number_tuberculosis   NUMERIC(18, 6),
    number_smallpox       NUMERIC(18, 6),
    number_cholera_cases  NUMERIC(18, 6),
    UNIQUE (entity_id, year)
);

INSERT INTO cases (
    entity_id, year, number_yaws, polio_cases, cases_guinea_worm, number_rabies,
    number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases
)
SELECT
    e.id,
    ic.year::INTEGER,
    ic.number_yaws::NUMERIC,
    ic.polio_cases::NUMERIC,
    ic.cases_guinea_worm::NUMERIC,
    ic.number_rabies::NUMERIC,
    ic.number_malaria::NUMERIC,
    ic.number_hiv::NUMERIC,
    ic.number_tuberculosis::NUMERIC,
    ic.number_smallpox::NUMERIC,
    ic.number_cholera_cases::NUMERIC
FROM infectious_cases AS ic
JOIN entities AS e ON e.entity = ic.entity
ORDER BY e.id, ic.year::INTEGER;

-- 3. Статистика Number_rabies
SELECT
    e.id,
    e.entity,
    e.code,
    ROUND(AVG(c.number_rabies), 2) AS avg_rabies,
    MIN(c.number_rabies)           AS min_rabies,
    MAX(c.number_rabies)           AS max_rabies,
    SUM(c.number_rabies)           AS sum_rabies
FROM cases AS c
JOIN entities AS e ON e.id = c.entity_id
WHERE c.number_rabies IS NOT NULL
GROUP BY e.id, e.entity, e.code
ORDER BY AVG(c.number_rabies) DESC
LIMIT 10;

-- 4. Різниця в роках (вбудовані функції)
SELECT
    c.id,
    e.entity,
    c.year,
    make_date(c.year, 1, 1)                                                   AS first_jan,
    CURRENT_DATE                                                              AS today,
    DATE_PART('year', AGE(CURRENT_DATE, make_date(c.year, 1, 1)))::INTEGER   AS year_diff
FROM cases AS c
JOIN entities AS e ON e.id = c.entity_id
ORDER BY e.entity, c.year
LIMIT 10;

-- 5. Функція year_diff
CREATE OR REPLACE FUNCTION year_diff(p_year INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT DATE_PART('year', AGE(CURRENT_DATE, make_date(p_year, 1, 1)))::INTEGER
$$;

-- 5. Використання year_diff
SELECT
    e.entity,
    c.year,
    make_date(c.year, 1, 1) AS first_jan,
    year_diff(c.year)       AS year_diff_function
FROM cases AS c
JOIN entities AS e ON e.id = c.entity_id
ORDER BY e.entity, c.year
LIMIT 10;

-- 5. Функція avg_cases_per_period
CREATE OR REPLACE FUNCTION avg_cases_per_period(cases_per_year NUMERIC, divisor NUMERIC)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT cases_per_year / NULLIF(divisor, 0)
$$;

-- 5. Використання avg_cases_per_period
SELECT
    entity,
    year::INTEGER                                                  AS year,
    number_rabies::NUMERIC                                         AS rabies_per_year,
    ROUND(avg_cases_per_period(number_rabies::NUMERIC, 12), 2)     AS per_month,
    ROUND(avg_cases_per_period(number_rabies::NUMERIC, 4), 2)      AS per_quarter,
    ROUND(avg_cases_per_period(number_rabies::NUMERIC, 2), 2)      AS per_half_year
FROM infectious_cases
WHERE number_rabies ~ '^[0-9]+(\.[0-9]+)?$'
ORDER BY number_rabies::NUMERIC DESC
LIMIT 10;

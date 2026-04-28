-- ============================================================
-- STEP 3: RUN THE FULL GYG SITE SELECTION ANALYSIS
-- Paste into a NEW Snowflake worksheet and run all
-- ============================================================

USE DATABASE LOKKO_ANALYTICS;
USE SCHEMA GYG_EXPANSION;


-- ────────────────────────────────────────────────────────────
-- QUERY 1: Verify your geo points loaded correctly
-- You should see non-null GEOGRAPHY values like POINT(144.97 -37.78)
-- ────────────────────────────────────────────────────────────

SELECT
    STORE_NAME,
    SUBURB,
    FORMAT,
    LAT,
    LNG,
    GEO_POINT    -- should show POINT(lng lat) values
FROM LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES
ORDER BY STORE_NAME
LIMIT 5;


-- ────────────────────────────────────────────────────────────
-- QUERY 2: OPPORTUNITY SCORING
-- Scores every VIC suburb across 5 geomarketing factors
-- This is the core of what you'd deliver to GYG real estate team
-- ────────────────────────────────────────────────────────────

WITH SCORED AS (
    SELECT
        s.SUBURB_NAME,
        s.POPULATION,
        s.MEDIAN_HH_INC,
        s.MEDIAN_AGE,

        -- FACTOR 1: Population score (25% weight)
        -- More people = more potential customers
        ROUND(LEAST(s.POPULATION / 1000.0 * 20, 100), 0)   AS POP_SCORE,

        -- FACTOR 2: Income score (20% weight)
        -- GYG sweet spot: $1,200–$2,500/wk — can afford $15 burrito regularly
        ROUND(CASE
            WHEN s.MEDIAN_HH_INC BETWEEN 1200 AND 2500 THEN 100
            WHEN s.MEDIAN_HH_INC > 2500                THEN 75  -- too rich = less QSR
            ELSE                                             50  -- too low = price sensitive
        END, 0)                                              AS INC_SCORE,

        -- FACTOR 3: Youth score (20% weight)
        -- GYG core demographic is 22–38 year olds
        ROUND(CASE
            WHEN s.MEDIAN_AGE BETWEEN 25 AND 38 THEN 100
            WHEN s.MEDIAN_AGE < 25              THEN 85   -- students, still good
            ELSE                                     60   -- older skews away from QSR
        END, 0)                                              AS YOUTH_SCORE,

        -- FACTOR 4: Whitespace score (25% weight)
        -- No GYG within 3km = genuine gap in coverage = opportunity
        -- ST_DWITHIN(point_a, point_b, distance_metres) returns TRUE/FALSE
        CASE WHEN NOT EXISTS (
            SELECT 1
            FROM   LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES g
            WHERE  ST_DWITHIN(s.GEO_POINT, g.GEO_POINT, 3000)
        ) THEN 100 ELSE 0 END                                AS GAP_SCORE,

        -- FACTOR 5: Low competition score (10% weight)
        -- Fewer Mexican competitors nearby = less market pressure
        GREATEST(100 - (
            SELECT COUNT(*) * 25
            FROM   LOKKO_ANALYTICS.GYG_EXPANSION.COMPETITORS c
            WHERE  ST_DWITHIN(s.GEO_POINT, c.GEO_POINT, 2000)
            AND    c.BRAND IN ('Mad Mex', 'Zambrero', 'Taco Bell')
        ), 0)                                                AS COMP_SCORE

    FROM LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS s
    WHERE s.STATE = 'VIC'
)
SELECT
    SUBURB_NAME                                              AS SUBURB,
    POPULATION,
    '$' || MEDIAN_HH_INC                                    AS HH_INCOME_WK,
    MEDIAN_AGE,
    -- Weighted composite score
    ROUND(
        POP_SCORE   * 0.25 +
        INC_SCORE   * 0.20 +
        YOUTH_SCORE * 0.20 +
        GAP_SCORE   * 0.25 +
        COMP_SCORE  * 0.10
    , 1)                                                     AS OPPORTUNITY_SCORE
FROM SCORED
ORDER BY OPPORTUNITY_SCORE DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
-- QUERY 3: GAP ANALYSIS — TRUE WHITESPACE
-- Find high-population suburbs with NO GYG within 5km
-- These are your strongest expansion candidates
-- ────────────────────────────────────────────────────────────

SELECT
    s.SUBURB_NAME,
    s.POPULATION,
    '$' || s.MEDIAN_HH_INC                                  AS HH_INCOME,

    -- ST_DISTANCE returns metres — divide by 1000 for km
    ROUND(MIN(ST_DISTANCE(s.GEO_POINT, g.GEO_POINT)) / 1000, 2)
                                                             AS KM_TO_NEAREST_GYG,

    -- Which store IS the nearest?
    (SELECT STORE_NAME
     FROM   LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES
     ORDER BY ST_DISTANCE(s.GEO_POINT, GEO_POINT)
     LIMIT 1)                                                AS NEAREST_GYG_STORE,

    -- Count Mexican competitors within 3km
    (SELECT COUNT(*)
     FROM   LOKKO_ANALYTICS.GYG_EXPANSION.COMPETITORS c
     WHERE  ST_DWITHIN(s.GEO_POINT, c.GEO_POINT, 3000)
     AND    c.BRAND IN ('Mad Mex', 'Zambrero', 'Taco Bell'))
                                                             AS COMPETITORS_WITHIN_3KM

FROM       LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS  s
CROSS JOIN LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES   g

WHERE s.STATE      = 'VIC'
  AND s.POPULATION > 10000

GROUP BY
    s.SUBURB_NAME, s.POPULATION, s.MEDIAN_HH_INC, s.GEO_POINT

-- Only keep suburbs where nearest GYG is MORE than 5km away
HAVING MIN(ST_DISTANCE(s.GEO_POINT, g.GEO_POINT)) > 5000

ORDER BY s.POPULATION DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
-- QUERY 4: LATERAL JOIN — nearest GYG + drive time
-- LATERAL JOIN is a Snowflake power feature:
-- for EACH suburb row, it runs a sub-query to find the
-- single nearest GYG store — no manual CROSS JOIN needed
-- ────────────────────────────────────────────────────────────

SELECT
    s.SUBURB_NAME                                             AS SUBURB,
    nearest.STORE_NAME                                        AS NEAREST_GYG,

    -- Straight-line distance in km
    ROUND(ST_DISTANCE(s.GEO_POINT, nearest.GEO_POINT) / 1000, 2)
                                                              AS STRAIGHT_LINE_KM,

    -- Estimated drive time: straight line × 1.35 (urban detour factor) ÷ 40kph
    ROUND(ST_DISTANCE(s.GEO_POINT, nearest.GEO_POINT) / 1000 * 1.35 / 40 * 60, 0)
                                                              AS EST_DRIVE_MINS,

    -- Is the suburb inside or outside the 3km trade area?
    CASE WHEN ST_DWITHIN(s.GEO_POINT, nearest.GEO_POINT, 3000)
         THEN 'Inside catchment' ELSE 'Outside — gap exists' END
                                                              AS CATCHMENT_STATUS

FROM LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS s

-- The LATERAL keyword means: for each row in ABS_SUBURBS,
-- run this sub-query and return just the closest store
JOIN LATERAL (
    SELECT STORE_NAME, GEO_POINT
    FROM   LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES
    ORDER BY ST_DISTANCE(s.GEO_POINT, GEO_POINT)   -- order by distance ascending
    LIMIT 1                                          -- take only the nearest one
) nearest ON TRUE

WHERE s.STATE      = 'VIC'
  AND s.POPULATION > 10000

ORDER BY STRAIGHT_LINE_KM DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
-- QUERY 5: TRADE AREA ANALYSIS
-- If GYG opens at Point Cook Town Centre, how many
-- people live within the 3km catchment?
-- This is what you show on page 1 of a client report
-- ────────────────────────────────────────────────────────────

WITH CANDIDATE_SITE AS (
    SELECT
        'Point Cook Town Centre'                AS SITE_NAME,
        ST_MAKEPOINT(144.7498, -37.9012)        AS SITE_GEO,  -- IMPORTANT: lng first, then lat
        3000                                    AS TRADE_AREA_METRES
)
SELECT
    c.SITE_NAME,
    SUM(s.POPULATION)                           AS CATCHMENT_POPULATION,
    '$' || ROUND(AVG(s.MEDIAN_HH_INC), 0)       AS AVG_HH_INCOME_WK,
    ROUND(AVG(s.MEDIAN_AGE), 0)                 AS AVG_MEDIAN_AGE,

    -- Estimated weekly customer visits (industry benchmark: 2% of catchment pop/week)
    ROUND(SUM(s.POPULATION) * 0.02, 0)          AS EST_WEEKLY_CUSTOMERS,

    -- Estimated weekly revenue at $18 average spend
    '$' || ROUND(SUM(s.POPULATION) * 0.02 * 18, 0)
                                                AS EST_WEEKLY_REVENUE,

    -- Estimated annual revenue
    '$' || ROUND(SUM(s.POPULATION) * 0.02 * 18 * 52, 0)
                                                AS EST_ANNUAL_REVENUE,

    COUNT(s.SA2_CODE)                           AS SUBURBS_IN_CATCHMENT

FROM      CANDIDATE_SITE c
CROSS JOIN LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS s

-- ST_DWITHIN: is suburb centroid within 3000m of candidate site?
WHERE ST_DWITHIN(c.SITE_GEO, s.GEO_POINT, c.TRADE_AREA_METRES)

GROUP BY c.SITE_NAME;


-- ────────────────────────────────────────────────────────────
-- QUERY 6: FINAL EXECUTIVE REPORT
-- Top 5 GYG expansion sites with format recommendation
-- This is the actual deliverable — paste into a PDF or
-- connect directly to Tableau/Power BI
-- ────────────────────────────────────────────────────────────

WITH BASE_SCORES AS (
    SELECT
        s.SUBURB_NAME,
        s.POPULATION,
        s.MEDIAN_HH_INC,
        s.MEDIAN_AGE,

        -- Distance to nearest GYG
        MIN(ST_DISTANCE(s.GEO_POINT, g.GEO_POINT) / 1000)  AS KM_TO_GYG,

        -- Composite opportunity score
        ROUND(
            LEAST(s.POPULATION / 1000.0 * 20, 100) * 0.25 +
            CASE WHEN s.MEDIAN_HH_INC BETWEEN 1200 AND 2500 THEN 100 ELSE 70 END * 0.20 +
            CASE WHEN s.MEDIAN_AGE    BETWEEN 25   AND 38   THEN 100 ELSE 70 END * 0.20 +
            CASE WHEN MIN(ST_DISTANCE(s.GEO_POINT, g.GEO_POINT)) > 3000 THEN 100 ELSE 0 END * 0.25 +
            GREATEST(100 - (
                SELECT COUNT(*) * 25
                FROM   LOKKO_ANALYTICS.GYG_EXPANSION.COMPETITORS c
                WHERE  ST_DWITHIN(s.GEO_POINT, c.GEO_POINT, 2000)
                AND    c.BRAND IN ('Mad Mex', 'Zambrero', 'Taco Bell')
            ), 0) * 0.10
        , 1)                                                 AS OPPORTUNITY_SCORE

    FROM      LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS s
    CROSS JOIN LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES  g

    WHERE s.STATE = 'VIC' AND s.POPULATION > 8000

    GROUP BY
        s.SUBURB_NAME, s.POPULATION, s.MEDIAN_HH_INC,
        s.MEDIAN_AGE, s.GEO_POINT

    -- Only recommend suburbs with genuine whitespace (>4km from existing GYG)
    HAVING MIN(ST_DISTANCE(s.GEO_POINT, g.GEO_POINT)) > 4000
)
SELECT
    SUBURB_NAME                                              AS SUBURB,
    POPULATION,
    '$' || MEDIAN_HH_INC                                    AS HH_INCOME_WK,
    MEDIAN_AGE,
    ROUND(KM_TO_GYG, 1)                                     AS KM_TO_NEAREST_GYG,
    OPPORTUNITY_SCORE,

    -- Format recommendation based on suburb profile
    CASE
        WHEN MEDIAN_AGE < 34 AND MEDIAN_HH_INC > 1500      THEN 'Inline + 24/7'
        WHEN POPULATION > 18000                             THEN 'Drive-thru'
        ELSE                                                     'Inline'
    END                                                      AS RECOMMENDED_FORMAT,

    -- Priority tier
    CASE
        WHEN OPPORTUNITY_SCORE >= 95 THEN 'Priority 1 — open now'
        WHEN OPPORTUNITY_SCORE >= 85 THEN 'Priority 2 — plan for FY26'
        ELSE                              'Priority 3 — monitor'
    END                                                      AS PRIORITY

FROM BASE_SCORES
ORDER BY OPPORTUNITY_SCORE DESC
LIMIT 5;

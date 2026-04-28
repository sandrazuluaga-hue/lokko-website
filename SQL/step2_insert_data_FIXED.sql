-- ============================================================
-- STEP 2 FIXED: INSERT DATA — fully qualified names everywhere
-- No USE DATABASE or USE SCHEMA needed — works in any session
-- 
-- HOW TO RUN:
-- 1. Select ALL text in this file (Cmd+A on Mac, Ctrl+A on Windows)
-- 2. Click the small arrow next to the Run button → "Run All"
-- OR click each INSERT block, select it, Cmd+Enter to run
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- INSERT GYG STORES (15 Melbourne locations)
-- ────────────────────────────────────────────────────────────

INSERT INTO LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES
    (STORE_ID, STORE_NAME, ADDRESS, SUBURB, STATE, POSTCODE, LAT, LNG, FORMAT)
VALUES
    ('GYG001', 'GYG Fitzroy',         '381 Smith St',          'Fitzroy',       'VIC', '3065', -37.8047, 144.9793, 'inline'),
    ('GYG002', 'GYG Brunswick',       '315 Sydney Rd',         'Brunswick',     'VIC', '3056', -37.7649, 144.9598, 'inline'),
    ('GYG003', 'GYG Northcote',       '259 High St',           'Northcote',     'VIC', '3070', -37.7682, 145.0019, 'inline'),
    ('GYG004', 'GYG Footscray',       '82 Hopkins St',         'Footscray',     'VIC', '3011', -37.7998, 144.8997, 'inline'),
    ('GYG005', 'GYG South Yarra',     'Shop 1 Jam Factory',    'South Yarra',   'VIC', '3141', -37.8432, 144.9931, 'inline'),
    ('GYG006', 'GYG Richmond',        '200 Bridge Rd',         'Richmond',      'VIC', '3121', -37.8198, 145.0012, 'inline'),
    ('GYG007', 'GYG Box Hill',        '1 Main St',             'Box Hill',      'VIC', '3128', -37.8197, 145.1218, 'drive-thru'),
    ('GYG008', 'GYG Glen Waverley',   '235 Springvale Rd',     'Glen Waverley', 'VIC', '3150', -37.8779, 145.1630, 'drive-thru'),
    ('GYG009', 'GYG Ringwood',        'Eastland SC',           'Ringwood',      'VIC', '3134', -37.8136, 145.2285, 'inline'),
    ('GYG010', 'GYG Berwick',         'Westfield Fountaingate','Berwick',       'VIC', '3806', -38.0337, 145.3464, 'drive-thru'),
    ('GYG011', 'GYG Craigieburn',     'Craigieburn Central',   'Craigieburn',   'VIC', '3064', -37.5997, 144.9443, 'drive-thru'),
    ('GYG012', 'GYG Essendon',        'Essendon DFO',          'Essendon',      'VIC', '3040', -37.7380, 144.9140, 'inline'),
    ('GYG013', 'GYG Doncaster',       'Westfield Doncaster',   'Doncaster',     'VIC', '3108', -37.7868, 145.1269, 'inline'),
    ('GYG014', 'GYG St Kilda',        '133 Fitzroy St',        'St Kilda',      'VIC', '3182', -37.8681, 144.9802, 'inline_24_7'),
    ('GYG015', 'GYG Carlton',         '209 Lygon St',          'Carlton',       'VIC', '3053', -37.8001, 144.9673, 'inline_24_7');


-- Set GEOGRAPHY column from LAT/LNG
-- ST_MAKEPOINT(longitude, latitude) — longitude comes FIRST
UPDATE LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES
SET    GEO_POINT = ST_MAKEPOINT(LNG, LAT)
WHERE  GEO_POINT IS NULL;


-- ────────────────────────────────────────────────────────────
-- INSERT ABS SUBURBS (40 Melbourne SA2 areas)
-- ────────────────────────────────────────────────────────────

INSERT INTO LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS
    (SA2_CODE, SUBURB_NAME, STATE, POPULATION, MEDIAN_AGE,
     MEDIAN_HH_INC, PCT_FAMILIES, PCT_RENTERS, CENTROID_LAT, CENTROID_LNG)
VALUES
    ('206041105', 'Fitzroy North',    'VIC', 12527, 30, 1803, 38.2, 42.1, -37.7841, 144.9778),
    ('206041106', 'Brunswick East',   'VIC', 14302, 30, 1574, 31.4, 55.3, -37.7693, 144.9916),
    ('206041121', 'Preston',          'VIC', 18979, 34, 1388, 42.1, 38.9, -37.7423, 144.9997),
    ('206041103', 'Coburg',           'VIC', 16742, 32, 1467, 40.3, 44.2, -37.7439, 144.9657),
    ('206041125', 'Thornbury',        'VIC', 15122, 33, 1688, 36.8, 47.6, -37.7556, 144.9994),
    ('206041122', 'Reservoir',        'VIC', 20985, 37, 1294, 45.2, 35.1, -37.7219, 145.0107),
    ('206041108', 'Footscray',        'VIC', 12951, 31, 1275, 33.1, 58.4, -37.7997, 144.8997),
    ('206041101', 'Altona',           'VIC', 11349, 39, 1749, 48.3, 24.6, -37.8688, 144.8301),
    ('206041119', 'Newport',          'VIC',  8400, 39, 1820, 46.1, 28.3, -37.8456, 144.8726),
    ('206041124', 'Sunshine',         'VIC', 17605, 35, 1138, 47.8, 41.2, -37.7885, 144.8297),
    ('206041126', 'Williamstown',     'VIC', 13200, 41, 1950, 49.2, 22.1, -37.8631, 144.8899),
    ('206041120', 'Northcote',        'VIC', 16100, 32, 1720, 34.6, 51.8, -37.7721, 145.0072),
    ('206041111', 'Heidelberg',       'VIC',  9800, 38, 1580, 46.7, 31.4, -37.7554, 145.0619),
    ('206041123', 'Ringwood',         'VIC', 14300, 37, 1640, 49.1, 29.8, -37.8136, 145.2285),
    ('206041102', 'Box Hill',         'VIC', 19200, 36, 1510, 44.3, 38.7, -37.8197, 145.1218),
    ('206041104', 'Dandenong',        'VIC', 22400, 33, 1120, 51.2, 48.3, -37.9876, 145.2166),
    ('206041109', 'Frankston',        'VIC', 18700, 38, 1280, 47.6, 34.2, -38.1442, 145.1258),
    ('206041127', 'Werribee',         'VIC', 16323, 34, 1340, 52.3, 31.1, -37.9022, 144.6597),
    ('206041128', 'Point Cook',       'VIC', 21843, 35, 1720, 58.4, 18.2, -37.9012, 144.7498),
    ('206041129', 'Craigieburn',      'VIC', 24600, 32, 1580, 61.2, 15.4, -37.5997, 144.9443),
    ('206041130', 'Epping',           'VIC', 19300, 33, 1490, 55.8, 22.6, -37.6464, 145.0208),
    ('206041131', 'Doncaster',        'VIC', 13600, 42, 2180, 52.1, 18.9, -37.7868, 145.1269),
    ('206041132', 'Glen Waverley',    'VIC', 17800, 40, 2240, 56.3, 14.2, -37.8779, 145.1630),
    ('206041133', 'Clayton',          'VIC', 12900, 30, 1310, 35.2, 52.4, -37.9200, 145.1183),
    ('206041134', 'Oakleigh',         'VIC', 11400, 37, 1620, 43.8, 36.7, -37.8983, 145.0939),
    ('206041135', 'Moonee Ponds',     'VIC', 10800, 34, 1880, 38.4, 44.1, -37.7644, 144.9196),
    ('206041136', 'Essendon',         'VIC', 14200, 38, 2050, 46.9, 28.3, -37.7510, 144.9213),
    ('206041137', 'St Kilda',         'VIC',  9600, 31, 1480, 24.1, 68.9, -37.8676, 144.9818),
    ('206041138', 'South Yarra',      'VIC', 11200, 30, 2120, 26.3, 64.2, -37.8399, 144.9929),
    ('206041139', 'Richmond',         'VIC', 13800, 31, 1790, 29.8, 58.1, -37.8183, 144.9998),
    ('206041140', 'Carlton',          'VIC',  8900, 25, 1240, 18.6, 74.3, -37.8001, 144.9673),
    ('206041141', 'Docklands',        'VIC',  6200, 33, 2380, 22.4, 71.8, -37.8147, 144.9439),
    ('206041142', 'Berwick',          'VIC', 23100, 36, 1890, 62.4, 14.8, -38.0337, 145.3464),
    ('206041143', 'Narre Warren',     'VIC', 25800, 34, 1650, 60.1, 19.3, -38.0224, 145.2994),
    ('206041144', 'Hoppers Crossing', 'VIC', 20400, 35, 1420, 57.8, 24.6, -37.8814, 144.7024),
    ('206041145', 'Springvale',       'VIC', 15600, 34, 1190, 49.3, 42.1, -37.9479, 145.1519),
    ('206041146', 'Rowville',         'VIC', 18200, 39, 1980, 56.7, 16.3, -37.9263, 145.2291),
    ('206041147', 'Knox',             'VIC', 16900, 40, 1870, 54.2, 19.8, -37.8954, 145.2426),
    ('206041148', 'Wantirna',         'VIC', 12100, 42, 2010, 55.9, 15.1, -37.8614, 145.2275),
    ('206041149', 'Templestowe',      'VIC', 11800, 44, 2350, 58.3, 11.2, -37.7497, 145.1629);


UPDATE LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS
SET    GEO_POINT = ST_MAKEPOINT(CENTROID_LNG, CENTROID_LAT)
WHERE  GEO_POINT IS NULL;


-- ────────────────────────────────────────────────────────────
-- INSERT COMPETITORS (12 Melbourne locations)
-- ────────────────────────────────────────────────────────────

INSERT INTO LOKKO_ANALYTICS.GYG_EXPANSION.COMPETITORS
    (COMP_ID, BRAND, SUBURB, STATE, LAT, LNG)
VALUES
    ('COMP001', 'Mad Mex',  'Fitzroy',       'VIC', -37.8010, 144.9790),
    ('COMP002', 'Mad Mex',  'Melbourne CBD', 'VIC', -37.8136, 144.9631),
    ('COMP003', 'Mad Mex',  'Richmond',      'VIC', -37.8201, 145.0010),
    ('COMP004', 'Mad Mex',  'Box Hill',      'VIC', -37.8200, 145.1220),
    ('COMP005', 'Zambrero', 'Carlton',       'VIC', -37.8005, 144.9680),
    ('COMP006', 'Zambrero', 'South Yarra',   'VIC', -37.8430, 144.9935),
    ('COMP007', 'Zambrero', 'Doncaster',     'VIC', -37.7870, 145.1270),
    ('COMP008', 'Zambrero', 'Dandenong',     'VIC', -37.9876, 145.2166),
    ('COMP009', 'Taco Bell','Melbourne CBD', 'VIC', -37.8142, 144.9631),
    ('COMP010', 'Taco Bell','Frankston',     'VIC', -38.1442, 145.1258),
    ('COMP011', 'Mad Mex',  'Moonee Ponds',  'VIC', -37.7644, 144.9196),
    ('COMP012', 'Zambrero', 'Clayton',       'VIC', -37.9200, 145.1183);


UPDATE LOKKO_ANALYTICS.GYG_EXPANSION.COMPETITORS
SET    GEO_POINT = ST_MAKEPOINT(LNG, LAT)
WHERE  GEO_POINT IS NULL;


-- ────────────────────────────────────────────────────────────
-- FINAL CHECK — you should see 15 / 40 / 12
-- ────────────────────────────────────────────────────────────

SELECT 'GYG_STORES'  AS TABLE_NAME, COUNT(*) AS ROW_COUNT
FROM   LOKKO_ANALYTICS.GYG_EXPANSION.GYG_STORES
UNION ALL
SELECT 'ABS_SUBURBS', COUNT(*)
FROM   LOKKO_ANALYTICS.GYG_EXPANSION.ABS_SUBURBS
UNION ALL
SELECT 'COMPETITORS', COUNT(*)
FROM   LOKKO_ANALYTICS.GYG_EXPANSION.COMPETITORS;

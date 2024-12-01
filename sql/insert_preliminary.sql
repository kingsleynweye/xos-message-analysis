PRAGMA FOREIGN_KEYS = ON;

INSERT INTO gamepigeon_application (name)
VALUES
    ('8 Ball'), 
    ('8 Ball+'), 
    ('Archery'), 
    ('8-Ball'),
    ('Anagrams'),
    ('Newbie Checkers'),
    ('9 Ball'),
    ('Basketball'),
    ('Paintball'),
    ('Cup Pong'),
    ('Mancala'),
    ('Tanks'),
    ('Dots & Boxes'),
    ('Filler'), 
    ('Mini Golf')
ON CONFLICT (name) DO NOTHING
;

INSERT INTO gamepigeon_application_rename (name_id, rename_id)
VALUES
    ((SELECT id FROM gamepigeon_application WHERE name = '8-Ball'), (SELECT id FROM gamepigeon_application WHERE name = '8 Ball')),
    ((SELECT id FROM gamepigeon_application WHERE name = '8 Ball+'), (SELECT id FROM gamepigeon_application WHERE name = '8 Ball'))
ON CONFLICT (name_id) DO UPDATE SET rename_id = EXCLUDED.rename_id
;

INSERT INTO gamepigeon_termination_type (id, description)
VALUES
    (1, 'Won'),
    (2, 'Lost'),
    (3, 'Draw'),
    (4, 'Unknown or exited')
ON CONFLICT (description) DO NOTHING
;

INSERT INTO area_code_metadata (value)
VALUES
    ('332'),
    ('470'),
    ('872'),
    ('945'),
    ('659'),
    ('474'),
    ('447'),
    ('1'),
    ('800'),
    ('833'),
    ('844'),
    ('855'),
    ('877'),
    ('888')
ON CONFLICT (value) DO NOTHING
;

INSERT INTO area_code_blacklist (country_area_code_id, city_area_code_id)
VALUES 
    ((SELECT id FROM area_code_metadata WHERE value = '1'), (SELECT id FROM area_code_metadata WHERE value = '800')),
    ((SELECT id FROM area_code_metadata WHERE value = '1'), (SELECT id FROM area_code_metadata WHERE value = '833')),
    ((SELECT id FROM area_code_metadata WHERE value = '1'), (SELECT id FROM area_code_metadata WHERE value = '844')),
    ((SELECT id FROM area_code_metadata WHERE value = '1'), (SELECT id FROM area_code_metadata WHERE value = '855')),
    ((SELECT id FROM area_code_metadata WHERE value = '1'), (SELECT id FROM area_code_metadata WHERE value = '877')),
    ((SELECT id FROM area_code_metadata WHERE value = '1'), (SELECT id FROM area_code_metadata WHERE value = '888'))
ON CONFLICT (country_area_code_id, city_area_code_id) DO NOTHING;

INSERT INTO country_metadata (name, fips, area_code_id, latitude, longitude)
VALUES
    ('United Kingdom', 'UK', (SELECT id FROM area_code_metadata WHERE value = '447'), 54.0, -2.0),
    ('United States', 'US', (SELECT id FROM area_code_metadata WHERE value = '1'), 0, 0),
    ('Canada', 'CA', (SELECT id FROM area_code_metadata WHERE value = '1'), 0, 0)
ON CONFLICT (name, area_code_id) DO NOTHING
;


INSERT INTO city_name (name)
VALUES
    ('Chicago'),
    ('Saskatoon'),
    ('North Battleford'),
    ('Prince Albert'),
    ('Regina'),
    ('Manhattan'),
    ('Atlanta'),
    ('Fort Worth'),
    ('Birmingham')
ON CONFLICT (name) DO NOTHING
;

INSERT INTO state_name (name)
VALUES
    ('Illinois'),
    ('New York'),
    ('Georgia'),
    ('Texas'),
    ('Alabama'),
    ('Saskatchewan')
ON CONFLICT (name) DO NOTHING
;

INSERT INTO city_metadata (country_id, city_name_id, state_name_id, area_code_id, latitude, longitude)
VALUES
    (
        (SELECT id FROM country_metadata WHERE name = 'United States'), 
        (SELECT id FROM city_name WHERE name = 'Manhattan'), 
        (SELECT id FROM state_name WHERE name = 'New York'), 
        (SELECT id FROM area_code_metadata WHERE value = '332'), 
        39.18361, -96.57167),
    (
        (SELECT id FROM country_metadata WHERE name = 'United States'), 
        (SELECT id FROM city_name WHERE name = 'Atlanta'), 
        (SELECT id FROM state_name WHERE name = 'Georgia'), 
        (SELECT id FROM area_code_metadata WHERE value = '470'), 
        33.749, -84.38798),
    (
        (SELECT id FROM country_metadata WHERE name = 'United States'), 
        (SELECT id FROM city_name WHERE name = 'Chicago'), 
        (SELECT id FROM state_name WHERE name = 'Illinois'),
        (SELECT id FROM area_code_metadata WHERE value = '872'), 
        41.8781, -87.623177),
    (
        (SELECT id FROM country_metadata WHERE name = 'United States'), 
        (SELECT id FROM city_name WHERE name = 'Fort Worth'), 
        (SELECT id FROM state_name WHERE name = 'Texas'), 
        (SELECT id FROM area_code_metadata WHERE value = '945'), 
        32.72541, -97.32085),
    (
        (SELECT id FROM country_metadata WHERE name = 'United States'), 
        (SELECT id FROM city_name WHERE name = 'Birmingham'), 
        (SELECT id FROM state_name WHERE name = 'Alabama'), 
        (SELECT id FROM area_code_metadata WHERE value = '659'), 
        33.52066, -86.80249),
    (
        (SELECT id FROM country_metadata WHERE name = 'Canada'), 
        (SELECT id FROM city_name WHERE name = 'Saskatoon'), 
        (SELECT id FROM state_name WHERE name = 'Saskatchewan'), 
        (SELECT id FROM area_code_metadata WHERE value = '474'), 
        52.1579, -106.6702),
    (
        (SELECT id FROM country_metadata WHERE name = 'Canada'), 
        (SELECT id FROM city_name WHERE name = 'North Battleford'), 
        (SELECT id FROM state_name WHERE name = 'Saskatchewan'), 
        (SELECT id FROM area_code_metadata WHERE value = '474'), 
        52.7575, -108.2975),
    (
        (SELECT id FROM country_metadata WHERE name = 'Canada'), 
        (SELECT id FROM city_name WHERE name = 'Prince Albert'), 
        (SELECT id FROM state_name WHERE name = 'Saskatchewan'), 
        (SELECT id FROM area_code_metadata WHERE value = '474'), 
        53.2033, -105.7531),
    (
        (SELECT id FROM country_metadata WHERE name = 'Canada'), 
        (SELECT id FROM city_name WHERE name = 'Regina'), 
        (SELECT id FROM state_name WHERE name = 'Saskatchewan'), 
        (SELECT id FROM area_code_metadata WHERE value = '474'), 
        50.4452, -104.6189)
ON CONFLICT (country_id, city_name_id, state_name_id, area_code_id) 
    DO UPDATE SET (latitude, longitude) = (EXCLUDED.latitude, EXCLUDED.longitude);
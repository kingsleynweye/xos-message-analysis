PRAGMA FOREIGN_KEYS = ON;

DROP VIEW IF EXISTS dashboard_user_restricted_view;
DROP VIEW IF EXISTS dashboard_handle_and_location_summary;
DROP VIEW IF EXISTS handle_area_code_summary;
DROP VIEW IF EXISTS contact_handle_map;
DROP VIEW IF EXISTS contact_name_email_and_phone_number_summary;
DROP VIEW IF EXISTS recent_chat_message_join;
DROP VIEW IF EXISTS contact_phone_number_summary;
DROP VIEW IF EXISTS contact_email_address_summary;
DROP VIEW IF EXISTS contact_name_summary;
DROP TABLE IF EXISTS grafana_restricted_user_handle_whitelist;
DROP TABLE IF EXISTS grafana_user_metadata;
DROP TABLE IF EXISTS dashboard_message_summary;
DROP TABLE IF EXISTS city_metadata;
DROP TABLE IF EXISTS state_name;
DROP TABLE IF EXISTS city_name;
DROP TABLE IF EXISTS country_metadata;
DROP TABLE IF EXISTS area_code_blacklist;
DROP TABLE IF EXISTS area_code_metadata;
DROP TABLE IF EXISTS word_cloud_word_message;
DROP TABLE IF EXISTS word_cloud_word;
DROP TABLE IF EXISTS handle_blacklist;
DROP TABLE IF EXISTS gamepigeon_session;
DROP TABLE IF EXISTS gamepigeon_termination;
DROP TABLE IF EXISTS gamepigeon_application_rename;
DROP TABLE IF EXISTS gamepigeon_application;
DROP TABLE IF EXISTS parsed_message_attributed_body;
DROP TABLE IF EXISTS contact_email_address;
DROP TABLE IF EXISTS contact_phone_number;
DROP TABLE IF EXISTS email_address;
DROP TABLE IF EXISTS phone_number;
DROP TABLE IF EXISTS contact;
DROP TABLE IF EXISTS contact_department;
DROP TABLE IF EXISTS contact_company;
DROP TABLE IF EXISTS contact_name;

CREATE TABLE IF NOT EXISTS contact_name (
    id INTEGER NOT NULL,
    "value" TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE ("value")
);

CREATE TABLE IF NOT EXISTS contact_company (
    id INTEGER NOT NULL,
    "value" TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE ("value")
);

CREATE TABLE IF NOT EXISTS contact_department (
    id INTEGER NOT NULL,
    "value" TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE ("value")
);

CREATE TABLE IF NOT EXISTS contact (
    id INTEGER NOT NULL,
    first_name_id INTEGER,
    last_name_id INTEGER,
    middle_name_id INTEGER,
    company_id INTEGER,
    department_id INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (first_name_id) REFERENCES contact_name (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (last_name_id) REFERENCES contact_name (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (middle_name_id) REFERENCES contact_name (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (company_id) REFERENCES contact_company (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (department_id) REFERENCES contact_department (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS phone_number (
    id INTEGER NOT NULL,
    "value" TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE ("value")
);

CREATE TABLE IF NOT EXISTS email_address (
    id INTEGER NOT NULL,
    "value" TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE ("value")
);

CREATE TABLE IF NOT EXISTS contact_phone_number (
    id INTEGER NOT NULL,
    contact_id INTEGER NOT NULL,
    phone_number_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (contact_id) REFERENCES contact (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (phone_number_id) REFERENCES phone_number (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (phone_number_id)
);

CREATE TABLE IF NOT EXISTS contact_email_address (
    id INTEGER NOT NULL,
    contact_id INTEGER NOT NULL,
    email_address_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (contact_id) REFERENCES contact (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (email_address_id) REFERENCES email_address (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (email_address_id)
);

CREATE TABLE IF NOT EXISTS parsed_message_attributed_body (
    id INTEGER NOT NULL,
    message_rowid INTEGER NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (message_rowid) REFERENCES message (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (message_rowid)
);

CREATE TABLE IF NOT EXISTS gamepigeon_application (
    id INTEGER NOT NULL,
    name TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (name)
);


CREATE TABLE IF NOT EXISTS gamepigeon_application_rename (
    id INTEGER NOT NULL,
    name_id INTEGER NOT NULL,
    rename_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (name_id) REFERENCES gamepigeon_application (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (rename_id) REFERENCES gamepigeon_application (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (name_id)
);

CREATE TABLE IF NOT EXISTS gamepigeon_termination_type (
    id INTEGER NOT NULL,
    description TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (description)
);


CREATE TABLE IF NOT EXISTS gamepigeon_session (
    id INTEGER NOT NULL,
    associated_message_guid TEXT NOT NULL,
    application_id INTEGER NOT NULL,
    unix_start_timestamp TEXT NOT NULL,
    unix_end_timestamp TEXT NOT NULL,
    termination_type_id INTEGER NOT NULL,
    opponent_handle_rowid INTEGER NOT NULL,
    my_points INTEGER,
    opponent_points INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (application_id) REFERENCES gamepigeon_application (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (termination_type_id) REFERENCES gamepigeon_termination_type (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (opponent_handle_rowid) REFERENCES handle (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (associated_message_guid)
);

CREATE TABLE IF NOT EXISTS handle_blacklist (
    id INTEGER NOT NULL,
    handle_id TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (handle_id)
);

CREATE TABLE IF NOT EXISTS word_cloud_word (
    id INTEGER NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (value)
);

CREATE TABLE IF NOT EXISTS word_cloud_word_message (
    id INTEGER NOT NULL,
    word_id INTEGER NOT NULL,
    message_rowid INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (word_id) REFERENCES word_cloud_word (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (message_rowid) REFERENCES message (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS area_code_metadata (
    id INTEGER NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (value)
);

CREATE TABLE IF NOT EXISTS area_code_blacklist (
    id INTEGER NOT NULL,
    country_area_code_id INTEGER NOT NULL,
    city_area_code_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (country_area_code_id) REFERENCES area_code_metadata (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (city_area_code_id) REFERENCES area_code_metadata (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (country_area_code_id, city_area_code_id)
);

CREATE TABLE IF NOT EXISTS country_metadata (
    id INTEGER NOT NULL,
    name TEXT NOT NULL,
    fips TEXT NOT NULL,
    area_code_id INTEGER NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (area_code_id) REFERENCES area_code_metadata (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (name, area_code_id)
);

CREATE TABLE city_name (
    id INTEGER NOT NULL,
    name TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (name)
);

CREATE TABLE state_name (
    id INTEGER NOT NULL,
    name TEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (name)
);

CREATE TABLE city_metadata (
    id INTEGER NOT NULL,
    country_id INTEGER NOT NULL,
    city_name_id INTEGER NOT NULL,
    state_name_id INTEGER NOT NULL,
    area_code_id INTEGER NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (country_id) REFERENCES country_metadata (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (city_name_id) REFERENCES city_name (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (state_name_id) REFERENCES state_name (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (area_code_id) REFERENCES area_code_metadata (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (country_id, city_name_id, state_name_id, area_code_id)
);

CREATE TABLE IF NOT EXISTS grafana_user_metadata (
    id INTEGER NOT NULL,
    email_address_id INTEGER NOT NULL,
    contact_reference_handle_rowid INTEGER NOT NULL,
    restrict_view INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    FOREIGN KEY (email_address_id) REFERENCES email_address (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (contact_reference_handle_rowid) REFERENCES handle (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (email_address_id)
);

CREATE TABLE IF NOT EXISTS grafana_restricted_user_handle_whitelist (
    id INTEGER NOT NULL,
    "user_id" INTEGER NOT NULL,
    handle_rowid INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY ("user_id") REFERENCES grafana_user_metadata (id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (handle_rowid) REFERENCES handle (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE ("user_id", handle_rowid)
);

CREATE TABLE IF NOT EXISTS dashboard_message_summary (
    id INTEGER NOT NULL,
    message_rowid INTEGER NOT NULL,
    chat_service_name TEXT NOT NULL,
    message_is_from_me INTEGER NOT NULL,
    is_emote_message INTEGER NOT NULL,
    is_audio_message INTEGER NOT NULL,
    associated_message_guid TEXT,
    message_guid TEXT NOT NULL,
    is_gamepigeon_message INTEGER NOT NULL,
    unix_date INTEGER NOT NULL,
    unix_timestamp INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "timestamp" TEXT NOT NULL,
    handle_rowid INTEGER NOT NULL,
    handle_id TEXT NOT NULL,
    original_contact_display_name TEXT,
    contact_display_name TEXT NOT NULL,
    contact_display_location TEXT,
    contact_location_latitude REAL,
    contact_location_longitude REAL,
    my_handle_id TEXT NOT NULL,
    my_display_location TEXT,
    my_location_latitude REAL,
    my_location_longitude REAL,
     message_subject TEXT,
    message_text TEXT,
    PRIMARY KEY (id),
    FOREIGN KEY (message_rowid) REFERENCES message (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (handle_rowid) REFERENCES handle (ROWID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    UNIQUE (message_rowid)
);

CREATE VIEW contact_name_summary AS
    SELECT
        c.id AS contact_id,
        COALESCE(
            NULLIF(RTRIM(COALESCE(nf.value, '') || COALESCE(' ' || nl.value, ''), ' ,'), ''), 
            NULLIF(RTRIM(COALESCE(o.value, '') || COALESCE(' ' || d.value, ''), ' ,'), ''),
            'Unknown' || ' ' || c.id
                ) AS display_name,
        nf.value AS first_name,
        nl.value AS last_name,
        nm.value AS middle_name,
        o.value AS company,
        d.value AS department
    FROM contact c
    LEFT JOIN contact_name nf ON nf.id = c.first_name_id
    LEFT JOIN contact_name nl ON nl.id = c.last_name_id
    LEFT JOIN contact_name nm ON nm.id = c.middle_name_id
    LEFT JOIN contact_company o ON o.id = c.company_id
    LEFT JOIN contact_department d ON d.id = c.department_id
;

CREATE VIEW contact_email_address_summary AS
    SELECT
        c.contact_id,
        s.display_name,
        c.email_address_id,
        e.value AS email_address
    FROM contact_email_address c
    LEFT JOIN email_address e ON e.id = c.email_address_id
    LEFT JOIN contact_name_summary s ON s.contact_id = c.contact_id
;

CREATE VIEW contact_phone_number_summary AS
    SELECT
        c.contact_id,
        s.display_name,
        c.phone_number_id,
        e.value AS phone_number,
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(e.value, '(', ''),
                    ')' , ''), 
                '-', ''),
            '‑', ''),
        ' ', '') AS parsed_phone_number
    FROM contact_phone_number c
    LEFT JOIN phone_number e ON e.id = c.phone_number_id
    LEFT JOIN contact_name_summary s ON s.contact_id = c.contact_id
;

CREATE VIEW contact_name_email_and_phone_number_summary AS
    SELECT
        e.contact_id,
        e.display_name,
        NULL AS phone_number_id,
        e.email_address_id,
        e.email_address AS handle_id
    FROM contact_email_address_summary e
    
    UNION ALL
    
    SELECT
        n.contact_id,
        n.display_name,
        n.phone_number_id,
        NULL AS email_address_id,
        n.parsed_phone_number AS handle_id
    FROM contact_phone_number_summary n
;

CREATE VIEW contact_handle_map AS
    WITH n AS (
        SELECT
            ROW_NUMBER() OVER() AS row_reference,
            n.contact_id,
            n.display_name,
            n.phone_number_id,
            n.email_address_id,
            n.handle_id
        FROM contact_name_email_and_phone_number_summary n
    ), h AS (
        SELECT
            h.handle_rowid,
            h.handle_id,
            COALESCE(
                n1.row_reference, 
                    n2.row_reference, 
                        n3.row_reference, 
                            n4.row_reference, 
                                n5.row_reference) AS row_reference
        FROM (
            SELECT
                h.ROWID AS handle_rowid,
                REPLACE(h.id, 'tel:', '') AS handle_id
            FROM handle h
        ) h
        LEFT JOIN n n1 ON n1.handle_id = '+1' || h.handle_id
        LEFT JOIN n n2 ON n2.handle_id = '+234' || SUBSTR(h.handle_id, 2)
        LEFT JOIN n n3 ON n3.handle_id = h.handle_id
        LEFT JOIN n n4 ON n4.handle_id = SUBSTR(h.handle_id, 3) 
        LEFT JOIN n n5 ON n5.handle_id = '0' || SUBSTR(h.handle_id, 5)
    ), s AS (
        SELECT
            h.handle_rowid,
            n.contact_id,
            n.display_name,
            n.phone_number_id,
            n.email_address_id,
            COALESCE(CASE
                WHEN SUBSTR(h.handle_id, 1, 1) = '+' THEN h.handle_id 
                    ELSE n.handle_id END, h.handle_id) AS handle_id,
            n.handle_id AS contact_handle_id,
            h.handle_id AS original_handle_id
        FROM h
        LEFT JOIN n ON n.row_reference = h.row_reference
    )

    SELECT
        s.handle_rowid,
        s.contact_id,
        s.display_name,
        s.phone_number_id,
        s.email_address_id,
        s.handle_id,
        s.contact_handle_id,
        s.original_handle_id,
        ROW_NUMBER() OVER (PARTITION BY s.handle_id) AS duplicate_handle_id_order
    FROM s
;

CREATE VIEW recent_chat_message_join AS
    SELECT
        j.chat_id,
        j.message_id
    FROM (
        SELECT
            j.chat_id,
            j.message_id,
            ROW_NUMBER() OVER(PARTITION BY j.message_id ORDER BY c.last_read_message_timestamp DESC) AS ranking
        FROM chat_message_join j
        LEFT JOIN chat c ON c.ROWID = j.chat_id
    ) j 
    WHERE ranking = 1
;

CREATE VIEW handle_area_code_summary AS
    WITH h AS (
        SELECT DISTINCT
            COALESCE(h.handle_id, n.handle_id) AS handle_id,
            c.id AS country_id,
            t.id AS city_id
        FROM contact_handle_map h
        FULL OUTER JOIN contact_name_email_and_phone_number_summary n ON n.handle_id = h.handle_id
        LEFT JOIN area_code_metadata mc ON
            mc.value = SUBSTR(COALESCE(h.handle_id, n.handle_id), 2, 4)
            OR mc.value = SUBSTR(COALESCE(h.handle_id, n.handle_id), 2, 3)
            OR mc.value = SUBSTR(COALESCE(h.handle_id, n.handle_id), 2, 2)
            OR mc.value = SUBSTR(COALESCE(h.handle_id, n.handle_id), 2, 1)
        LEFT JOIN country_metadata c ON c.area_code_id = mc.id
        LEFT JOIN area_code_metadata mt ON
            mt.value = SUBSTR(COALESCE(h.handle_id, n.handle_id), LENGTH(mc.value) + 2, LENGTH(mt.value))
        LEFT JOIN city_metadata t ON 
            t.country_id = c.id
            AND t.area_code_id = mt.id
        LEFT JOIN (
            SELECT
                c.value || t.value AS value
            FROM area_code_blacklist b
            LEFT JOIN area_code_metadata c ON c.id = b.country_area_code_id
            LEFT JOIN area_code_metadata t ON t.id = b.city_area_code_id
        ) b ON b.value = SUBSTR(COALESCE(h.handle_id, n.handle_id), 2, LENGTH(b.value))
        WHERE 
            SUBSTR(COALESCE(h.handle_id, n.handle_id), 1, 1) = '+'
            AND b.value IS NULL
    ), fc AS (
        SELECT
            h.handle_id,
            COUNT(h.country_id) AS country_id_count,
            COUNT(h.city_id) AS city_id_count
        FROM h
        GROUP BY
            h.handle_id
    ), hc AS (
        SELECT
            h.handle_id,
            h.country_id,
            h.city_id
        FROM h 
        WHERE
            h.city_id IS NOT NULL
            OR (h.handle_id IN (SELECT handle_id FROM fc WHERE city_id_count = 0) 
                AND h.handle_id NOT IN (SELECT handle_id FROM fc WHERE city_id_count > 0))
    ), rc AS (
        SELECT
            hc.handle_id,
            hc.country_id,
            hc.city_id
        FROM hc
        LEFT JOIN (
            SELECT
                hc.handle_id,
                hc.country_id,
                hc.city_id,
                DENSE_RANK() OVER(PARTITION BY hc.handle_id ORDER BY LENGTH(m.value) DESC) AS ranking
            FROM hc
            LEFT JOIN country_metadata c ON c.id = hc.country_id
            LEFT JOIN area_code_metadata m ON m.id = c.area_code_id
        ) r ON 
            r.handle_id = hc.handle_id 
            AND r.country_id = hc.country_id
            AND COALESCE(r.city_id, 1) = COALESCE(hc.city_id, 1)
        WHERE r.ranking = 1
    ), a AS (
        SELECT
            rc.handle_id,
            rc.country_id,
            t.state_name_id,
            CASE WHEN COUNT(*) = 1 THEN rc.city_id END AS city_id,
            CASE WHEN COUNT(*) = 1 THEN t.city_name_id END AS city_name_id,
            AVG(COALESCE(t.latitude, c.latitude)) AS latitude,
            AVG(COALESCE(t.longitude, c.longitude)) AS longitude
        FROM rc
        LEFT JOIN country_metadata c ON c.id = rc.country_id
        LEFT JOIN city_metadata t ON t.id = rc.city_id
        GROUP BY
            rc.handle_id,
            rc.country_id,
            t.state_name_id
    )

    SELECT
        a.handle_id,
        NULLIF(TRIM(
            COALESCE(cn.name, '') 
                || COALESCE(', ' || sn.name, '') 
                    || COALESCE(', ' || c.name, ''), ' ,'), '') 
                        AS display_location,
        m.value AS area_code,
        c.name AS country,
        c.fips AS country_fips,
        sn.name AS state,
        cn.name AS city,
        a.latitude,
        a.longitude,
        a.country_id,
        a.state_name_id,
        a.city_name_id
    FROM a
    LEFT JOIN country_metadata c ON c.id = a.country_id
    LEFT JOIN city_metadata t ON t.id = a.city_id
    LEFT JOIN city_name cn ON cn.id = a.city_name_id
    LEFT JOIN state_name sn ON sn.id = a.state_name_id
    LEFT JOIN area_code_metadata m ON m.id = COALESCE(t.area_code_id, c.area_code_id)
;

CREATE VIEW dashboard_handle_and_location_summary AS
    WITH s AS (
        SELECT
            m.ROWID AS message_rowid,
            c.room_name,
            hcb.original_handle_id AS original_contact_handle_id,
            COALESCE(NULLIF(m.handle_id, 0), hcb.handle_rowid) AS contact_handle_rowid,
            COALESCE(hc.handle_id, nc.handle_id) AS contact_handle_id,
            COALESCE(hc.contact_id, nc.contact_id) AS contact_id,
            COALESCE(hc.display_name, nc.display_name) AS contact_display_name,
            ac.display_location AS contact_display_location,
            ac.latitude AS contact_location_latitude,
            ac.longitude AS contact_location_longitude,
            COALESCE(hm1.handle_id, hm2.handle_id, nm.handle_id) AS my_handle_id,
            COALESCE(hm1.contact_id, hm2.contact_id, nm.contact_id) AS my_contact_id,
            am.display_location AS my_display_location,
            am.latitude AS my_location_latitude,
            am.longitude AS my_location_longitude,
            m.date,
            STRFTIME('%Y', (m.date/1000000000.0) + 978307200, 'unixepoch') AS group_date,
            m.is_delivered,
            m.is_sent,
            m.service
        FROM message m
        LEFT JOIN recent_chat_message_join j ON j.message_id = m.ROWID
        LEFT JOIN chat c ON c.ROWID = j.chat_id
        LEFT JOIN (SELECT * FROM contact_handle_map WHERE duplicate_handle_id_order = 1) hcb ON 
            hcb.original_handle_id = c.chat_identifier
        LEFT JOIN contact_handle_map hc ON hc.handle_rowid = COALESCE(NULLIF(m.handle_id, 0), hcb.handle_rowid)
        LEFT JOIN contact_name_email_and_phone_number_summary nc ON nc.handle_id = c.chat_identifier
        LEFT JOIN handle_area_code_summary ac ON ac.handle_id = COALESCE(hc.handle_id, nc.handle_id)
        LEFT JOIN (SELECT DISTINCT handle_id, original_handle_id, contact_id FROM contact_handle_map) hm1 ON 
            hm1.original_handle_id = NULLIF(m.destination_caller_id, '')
        LEFT JOIN (
            SELECT
                c.handle_id, 
                c.original_handle_id, 
                c.contact_id,
                MIN(e.date) AS earliest_date,
                MAX(e.date) AS latest_date
            FROM contact_handle_map c
            INNER JOIN message e ON e.destination_caller_id = c.handle_id
            GROUP BY
                c.handle_id, 
                c.original_handle_id, 
                c.contact_id
        ) hm2 ON 
            hm2.original_handle_id = NULLIF(c.last_addressed_handle, '')
            AND m.date BETWEEN hm2.earliest_date AND latest_date
        LEFT JOIN contact_name_email_and_phone_number_summary nm ON nm.handle_id = COALESCE(NULLIF(m.destination_caller_id, ''), hm2.handle_id)
        LEFT JOIN handle_area_code_summary am ON am.handle_id = COALESCE(hm1.handle_id, hm2.handle_id, nm.handle_id)
    ), b AS (
        SELECT
            s.message_rowid,
            s.room_name,
            s.original_contact_handle_id,
            s.contact_handle_rowid,
            s.contact_handle_id,
            s.contact_id,
            s.contact_display_name,
            s.contact_display_location,
            s.contact_location_latitude,
            s.contact_location_longitude,
            COALESCE(s.my_handle_id, mb.my_handle_id, lmb.handle_id) AS my_handle_id,
            COALESCE(s.my_contact_id, mb.my_contact_id, lmb.contact_id) AS my_contact_id,
            s.my_display_location,
            s.my_location_latitude,
            s.my_location_longitude,
            s.date,
            s.group_date,
            s.is_delivered,
            s.is_sent,
            s.service
        FROM s
        LEFT JOIN (
            SELECT
                m.message_rowid,
                m.my_contact_id,
                m.my_handle_id
            FROM (
                SELECT
                    s.message_rowid,
                    e.my_contact_id,
                    e.my_handle_id,
                    ROW_NUMBER() OVER(PARTITION BY s.message_rowid ORDER BY (CASE 
                        WHEN ABS(s.date - e.earliest_date) <= ABS(s.date - e.latest_date) 
                            THEN ABS(s.date - e.earliest_date) 
                                ELSE ABS(s.date - e.latest_date) END)) AS ranking
                FROM s
                CROSS JOIN (
                    SELECT
                        s.my_handle_id,
                        s.my_contact_id,
                        MIN(s.date) AS earliest_date,
                        MAX(s.date) AS latest_date
                    FROM s
                    WHERE 
                        s.my_handle_id IS NOT NULL
                    GROUP BY
                        s.group_date,
                        s.my_handle_id,
                        s.my_contact_id
                ) e
                WHERE 
                    s.my_handle_id IS NULL
            ) m 
                WHERE m.ranking = 1
        ) mb ON mb.message_rowid = s.message_rowid
        CROSS JOIN (SELECT * FROM contact_handle_map WHERE handle_id = 'kings9649ja@icloud.com' LIMIT 1) lmb
    ), c AS (
        SELECT
            c.message_rowid,
            c.contact_display_location,
            c.contact_location_latitude,
            c.contact_location_longitude
        FROM (
            SELECT
                b.message_rowid,
                e.contact_display_location,
                e.contact_location_latitude,
                e.contact_location_longitude,
                ROW_NUMBER() OVER(PARTITION BY b.message_rowid ORDER BY (CASE 
                    WHEN ABS(b.date - e.earliest_date) <= ABS(b.date - e.latest_date) 
                        THEN ABS(b.date - e.earliest_date) 
                            ELSE ABS(b.date - e.latest_date) END)) AS ranking
            FROM b
            INNER JOIN (
                SELECT 
                    b.contact_id,
                    b.contact_handle_id,
                    b.contact_display_location,
                    b.contact_location_latitude,
                    b.contact_location_longitude,
                    MIN(b.date) AS earliest_date,
                    MAX(b.date) AS latest_date
                FROM b
                WHERE b.contact_display_location IS NOT NULL
                GROUP BY
                    b.group_date,
                    b.contact_id, 
                    b.contact_handle_id, 
                    b.contact_display_location,
                    b.contact_location_latitude,
                    b.contact_location_longitude
            ) e ON e.contact_id = b.contact_id
            WHERE
                b.contact_display_location IS NULL
        ) c
        WHERE c.ranking = 1
    ), m AS (
        SELECT
            c.message_rowid,
            c.my_display_location,
            c.my_location_latitude,
            c.my_location_longitude
        FROM (
            SELECT
                b.message_rowid,
                e.my_display_location,
                e.my_location_latitude,
                e.my_location_longitude,
                ROW_NUMBER() OVER(PARTITION BY b.message_rowid ORDER BY (CASE 
                    WHEN ABS(b.date - e.earliest_date) <= ABS(b.date - e.latest_date) 
                        THEN ABS(b.date - e.earliest_date) 
                            ELSE ABS(b.date - e.latest_date) END)) AS ranking
            FROM b
            CROSS JOIN (
                SELECT 
                    b.my_contact_id,
                    b.my_handle_id,
                    b.my_display_location,
                    b.my_location_latitude,
                    b.my_location_longitude,
                    MIN(b.date) AS earliest_date,
                    MAX(b.date) AS latest_date
                FROM b 
                WHERE b.my_display_location IS NOT NULL
                GROUP BY 
                    b.group_date,
                    b.my_contact_id,
                    b.my_handle_id, 
                    b.my_display_location,
                    b.my_location_latitude,
                    b.my_location_longitude
            ) e
            WHERE
                b.my_display_location IS NULL
        ) c
        WHERE c.ranking = 1
    )

    SELECT
        b.message_rowid,
        b.contact_handle_rowid,
        b.contact_handle_id,
        b.contact_id,
        b.contact_display_name,
        COALESCE(b.contact_display_location, c.contact_display_location) AS contact_display_location,
        COALESCE(b.contact_location_latitude, c.contact_location_latitude) AS contact_location_latitude,
        COALESCE(b.contact_location_longitude, c.contact_location_longitude) AS contact_location_longitude,
        b.my_handle_id,
        b.my_contact_id,
        COALESCE(b.my_display_location, m.my_display_location) AS my_display_location,
        COALESCE(b.my_location_latitude, m.my_location_latitude) AS my_location_latitude,
        COALESCE(b.my_location_longitude, m.my_location_longitude) AS my_location_longitude
    FROM b
    LEFT JOIN c ON c.message_rowid = b.message_rowid
    LEFT JOIN m ON m.message_rowid = b.message_rowid
    WHERE 
        (b.is_delivered = 1 OR b.is_sent = 1)
        AND b.room_name IS NULL
        AND b.original_contact_handle_id NOT IN (SELECT handle_id FROM handle_blacklist)
        AND b.service IN ('SMS', 'iMessage', 'Yahoo')
;

CREATE VIEW dashboard_user_restricted_view AS
    SELECT DISTINCT
        e.value AS user_email_address,
        m.contact_display_name,
        m.handle_id
    FROM grafana_user_metadata u
    LEFT JOIN email_address e ON e.id = u.email_address_id
    LEFT JOIN grafana_restricted_user_handle_whitelist w ON w.user_id = u.id
    CROSS JOIN (
        SELECT DISTINCT
            m.contact_display_name,
            m.handle_id,
            m.handle_rowid
        FROM dashboard_message_summary m
    ) m
    WHERE
        u.restrict_view = 0
        OR (u.restrict_view = 1 AND w.handle_rowid = m.handle_rowid)
;
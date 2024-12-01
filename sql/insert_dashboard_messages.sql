PRAGMA FOREIGN_KEYS = ON;

INSERT INTO dashboard_message_summary (
    message_rowid,
    chat_service_name,
    message_is_from_me,
    is_emote_message,
    is_audio_message,
    associated_message_guid,
    message_guid,
    is_gamepigeon_message,
    unix_date,
    unix_timestamp,
    "date",
    "timestamp",
    handle_rowid,
    handle_id,
    original_contact_display_name,
    contact_display_name,
    contact_display_location,
    contact_location_latitude,
    contact_location_longitude,
    my_handle_id,
    my_display_location,
    my_location_latitude,
    my_location_longitude,
    message_subject,
    message_text
)
    SELECT
        m.ROWID AS message_rowid,
        m.service AS chat_service_name,
        m.is_from_me AS message_is_from_me,
        m.is_emote AS is_emote_message,
        m.is_audio_message,
        m.associated_message_guid,
        m.guid AS message_guid,
        CASE 
            WHEN m.balloon_bundle_id 
                = 'com.apple.messages.MSMessageExtensionBalloonPlugin:EWFNLB79LQ:com.gamerdelights.gamepigeon.ext' 
                    THEN 1 ELSE 0 END is_gamepigeon_message,
        UNIXEPOCH(
            DATE((m.date/1000000000.0) + 978307200, 'unixepoch')) 
                AS unix_date,
        UNIXEPOCH((m.date/1000000000.0) + 978307200, 'unixepoch') 
            AS unix_timestamp,
        DATE((m.date/1000000000.0) + 978307200, 'unixepoch')
            AS date,
        DATETIME((m.date/1000000000.0) + 978307200, 'unixepoch') 
            AS timestamp,
        COALESCE(s.contact_handle_rowid, m.handle_id) AS handle_rowid,
        COALESCE(s.contact_handle_id, m.handle_id) AS handle_id,
        s.contact_display_name AS original_contact_display_name,
        COALESCE(s.contact_display_name, 'Unknown Contacts') AS contact_display_name,
        s.contact_display_location,
        s.contact_location_latitude,
        s.contact_location_longitude,
        s.my_handle_id,
        s.my_display_location,
        s.my_location_latitude,
        s.my_location_longitude,
        m.subject AS message_subject,
        COALESCE(m.text, p.value) AS message_text
    FROM message m
    INNER JOIN dashboard_handle_and_location_summary s ON s.message_rowid = m.ROWID
    LEFT JOIN parsed_message_attributed_body p ON p.message_rowid = m.ROWID
ON CONFLICT (message_rowid) DO NOTHING
;
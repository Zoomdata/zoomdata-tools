--DROP TABLE account_logs;

CREATE TABLE account_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    name text,
    created_by text,
    created_date timestamp without time zone,
    last_modified_by text,
    disabled text
);

-- DROP INDEX idx_account_event_date;

CREATE INDEX idx_account_event_date
    ON account_logs USING btree
    (event_date DESC);

--DROP TABLE authentication_logs;

CREATE TABLE authentication_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    authentication_type text
);

-- DROP INDEX idx_account_event_date;

CREATE INDEX idx_authentication_event_date
    ON authentication_logs USING btree
    (event_date DESC);

--DROP TABLE source_logs;

CREATE TABLE source_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    source_id text,
    source_name text,
    stream_type text,
    storage_type text,
    source_as_string text,
    source_description text
);

-- DROP INDEX idx_source_event_date;

CREATE INDEX idx_source_event_date
    ON source_logs USING btree
    (event_date DESC);

--DROP TABLE vis_logs;

CREATE TABLE vis_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    cid text,
    visualization_id text,
    visualization_name text
);

-- DROP INDEX idx_vis_event_date;

CREATE INDEX idx_vis_event_date
    ON vis_logs USING btree
    (event_date DESC);

--DROP TABLE vis_command_logs;

CREATE TABLE vis_command_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    cid text,
    action_started_on bigint,
    duration bigint,
    request text,
    source_id text,
    source_name text,
    source_type text,
    source_schema text,
    source_collection text,
    connection_id text
);

-- DROP INDEX idx_vis_command_event_date;

CREATE INDEX idx_vis_command_event_date
    ON vis_command_logs USING btree
    (event_date DESC);

--DROP TABLE vis_def_logs;

CREATE TABLE vis_def_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    cid text,
    visualization_id text,
    visualization_name text,
    source_id text
);

-- DROP INDEX idx_vis_def_event_date;

CREATE INDEX idx_vis_def_event_date
    ON vis_def_logs USING btree
    (event_date DESC);

--DROP TABLE vis_data_logs;

CREATE TABLE vis_data_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    payload text,
    cid text,
    action_started_on bigint,
    duration bigint
);

-- DROP INDEX idx_vis_data_event_date;

CREATE INDEX idx_vis_data_event_date
    ON vis_data_logs USING btree
    (event_date DESC);

--DROP TABLE raw_data_export_logs;

CREATE TABLE raw_data_export_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    export_type text,
    count bigint,
    storage_type text,
    query text,
    cid text,
    action_started_on bigint,
    duration bigint
);

-- DROP INDEX idx_raw_data_event_date;

CREATE INDEX idx_raw_data_event_date
    ON raw_data_export_logs USING btree
    (event_date DESC);

--DROP TABLE raw_data_export_csv_logs;

CREATE TABLE raw_data_export_csv_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    count bigint,
    location text,
    file text,
    cid text,
    action_started_on bigint,
    duration bigint
);

-- DROP INDEX idx_raw_data_csv_event_date;

CREATE INDEX idx_raw_data_csv_event_date
    ON raw_data_export_csv_logs USING btree
    (event_date DESC);

--DROP TABLE upload_logs;

CREATE TABLE upload_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    source text,
    file_name text,
    content_type text,
    file_size text
);

-- DROP INDEX idx_upload_event_date;

CREATE INDEX idx_upload_event_date
    ON upload_logs USING btree
    (event_date DESC);

--DROP TABLE user_logs;

CREATE TABLE user_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    user_id text,
    user_name text,
    user_full_name text,
    email text,
    subject_user_groups text,
    subject_user_roles text,
    user_origin text,
    accounts text
);

-- DROP INDEX idx_user_event_date;

CREATE INDEX idx_user_event_date
    ON user_logs USING btree
    (event_date DESC);

--DROP TABLE rdd_logs;

CREATE TABLE rdd_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    storage_type text,
    response_size bigint,
    queries text,
    cid text,
    proxied_user text,
    read_request text,
    action_started_on bigint,
    duration bigint,
    dashboard_id text,
    trace_id text,
    visualization_id text,
    visualization_name text
);

-- DROP INDEX idx_rdd_event_date;

CREATE INDEX idx_rdd_event_date
    ON rdd_logs USING btree
    (event_date DESC);

--DROP TABLE rdd_cache_logs;

CREATE TABLE rdd_cache_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    source_id text,
    query text
);

-- DROP INDEX idx_rdd_cache_event_date;

CREATE INDEX idx_rdd_cache_event_date
    ON rdd_cache_logs USING btree
    (event_date DESC);

--DROP TABLE group_logs;

CREATE TABLE group_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    group_id text,
    label text,
    description text,
    group_roles text
);

-- DROP INDEX idx_group_event_date;

CREATE INDEX idx_group_event_date
    ON group_logs USING btree
    (event_date DESC);

--DROP TABLE bookmark_logs;

CREATE TABLE bookmark_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    bookmark_id text,
    bookmark_name text,
    description text,
    shared text,
    key_ids text
);

-- DROP INDEX idx_bookmark_event_date;

CREATE INDEX idx_bookmark_event_date
    ON bookmark_logs USING btree
    (event_date DESC);

--DROP TABLE security_key_logs;

CREATE TABLE security_key_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    key_id text,
    created_date timestamp without time zone,
    expiration_date timestamp without time zone,
    description text,
    key_type text,
    object_ids text
);

-- DROP INDEX idx_security_key_event_date;

CREATE INDEX idx_security_key_event_date
    ON security_key_logs USING btree
    (event_date DESC);

--DROP TABLE oauth_client_logs;

CREATE TABLE oauth_client_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    client_id text,
    client_name text,
    auto_approve text
);

-- DROP INDEX idx_oauth_client_event_date;

CREATE INDEX idx_oauth_client_event_date
    ON oauth_client_logs USING btree
    (event_date DESC);

--DROP TABLE oauth_token_logs;

CREATE TABLE oauth_token_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    token_id text,
    client_id text,
    token_username text,
    token_account_id text
);

-- DROP INDEX idx_oauth_token_event_date;

CREATE INDEX idx_oauth_token_event_date
    ON oauth_token_logs USING btree
    (event_date DESC);

--DROP TABLE request_logs;

CREATE TABLE request_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    uri text,
    host text,
    request_processing_time bigint,
    request_size text,
    response_code text
);

-- DROP INDEX idx_request_event_date;

CREATE INDEX idx_request_event_date
    ON request_logs USING btree
    (event_date DESC);

--DROP TABLE topology_logs;

CREATE TABLE topology_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    cid text,
    action_started_on bigint,
    duration bigint
);

-- DROP INDEX idx_topology_event_date;

CREATE INDEX idx_topology_event_date
    ON topology_logs USING btree
    (event_date DESC);

-- DROP TABLE topology_performance_logs;

CREATE TABLE topology_performance_logs
(
    event_date timestamp without time zone,
    "user" text,
    user_type text,
    account_id text,
    user_groups text,
    user_roles text,
    ip text,
    activity_type text,
    status text,
    rdd_count int,
    cid text,
    timeline text,
    finish_status text,
    action_started_on bigint,
    duration bigint,
    topology_created bigint,
    topology_started bigint,
    vis_data_succeeded bigint,
    vis_command_finished bigint,
    topology_finished bigint
);

-- DROP INDEX idx_topology_perf_event_date;

CREATE INDEX idx_topology_perf_event_date
    ON topology_performance_logs USING btree
    (event_date DESC);

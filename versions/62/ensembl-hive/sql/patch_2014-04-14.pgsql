
    -- add a new meadow-agnostic table for tracking the resource usage:
CREATE TABLE worker_resource_usage (
    worker_id               INTEGER         NOT NULL,
    exit_status             VARCHAR(255)    DEFAULT NULL,
    mem_megs                FLOAT           DEFAULT NULL,
    swap_megs               FLOAT           DEFAULT NULL,
    pending_sec             FLOAT           DEFAULT NULL,
    cpu_sec                 FLOAT           DEFAULT NULL,
    lifespan_sec            FLOAT           DEFAULT NULL,
    exception_status        VARCHAR(255)    DEFAULT NULL,

    PRIMARY KEY (worker_id)
);


    -- add a foreign key:
ALTER TABLE worker_resource_usage   ADD FOREIGN KEY (worker_id)                 REFERENCES worker(worker_id)                    ON DELETE CASCADE;


    -- add a stats view over the new table:
CREATE OR REPLACE VIEW resource_usage_stats AS
    SELECT a.logic_name || '(' || a.analysis_id || ')' analysis,
           w.meadow_type,
           rc.name || '(' || rc.resource_class_id || ')' resource_class,
           count(*) workers,
           min(mem_megs) AS min_mem_megs, avg(mem_megs) AS avg_mem_megs, max(mem_megs) AS max_mem_megs,
           min(swap_megs) AS min_swap_megs, avg(swap_megs) AS avg_swap_megs, max(swap_megs) AS max_swap_megs
    FROM analysis_base a
    JOIN resource_class rc USING(resource_class_id)
    LEFT JOIN worker w USING(analysis_id)
    LEFT JOIN worker_resource_usage USING (worker_id)
    GROUP BY analysis_id, w.meadow_type, rc.resource_class_id
    ORDER BY analysis_id, w.meadow_type;


    -- add a new key to worker table to speed up mapping between process_id and worker_id:
CREATE        INDEX ON worker (meadow_type, meadow_name, process_id);

    -- UPDATE hive_sql_schema_version
UPDATE hive_meta SET meta_value=59 WHERE meta_key='hive_sql_schema_version' AND meta_value='58';


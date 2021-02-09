-- setup for COPY progress testing
CREATE TEMP TABLE test_progress_with_trigger (
  a int,
  b text
) ;

CREATE OR REPLACE function notice_after_progress_reporting() RETURNS trigger AS
$$
DECLARE report record;
BEGIN
  SELECT INTO report * FROM pg_stat_progress_copy report WHERE pid = pg_backend_pid();
  raise info 'progress datname: %', report.datname;
  raise info 'progress command: %', report.command;
  raise info 'progress io_target: %', report.io_target;
  raise info 'progress bytes_processed: %', report.bytes_processed;
  raise info 'progress bytes_total: %', report.bytes_total;
  raise info 'progress tuples_processed: %', report.tuples_processed;
  raise info 'progress tuples_excluded: %', report.tuples_excluded;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_after_progress_reporting
    AFTER INSERT ON test_progress_with_trigger
    FOR EACH ROW
    EXECUTE FUNCTION notice_after_progress_reporting();

-- simple COPY from STDIN
COPY test_progress_with_trigger (a, b) FROM STDIN;
1	test_1
\.

-- COPY from STDIN with WHERE skipping lines
COPY test_progress_with_trigger (a, b) FROM STDIN WHERE a > 1;
1	test_1
2	test_2
\.


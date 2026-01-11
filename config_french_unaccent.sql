CREATE EXTENSION IF NOT EXISTS unaccent;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_ts_config WHERE cfgname = 'french_unaccent'
    ) THEN
        CREATE TEXT SEARCH CONFIGURATION french_unaccent ( COPY = french );
    END IF;
END
$$;
ALTER TEXT SEARCH CONFIGURATION french_unaccent
ALTER MAPPING FOR hword, hword_part, word
WITH unaccent, french_stem;

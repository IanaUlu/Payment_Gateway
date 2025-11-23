#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Tables will be created by EF Core
    SELECT 'Database initialized successfully';
EOSQL

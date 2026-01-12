\set ON_ERROR_STOP on

\echo '== init =='
\ir init/00_init_db.sql
\ir init/01_roles_and_schemas.sql

\echo '== pre-structure utils =='
\ir logic/public/01_utils.sql

\echo '== structure =='
\ir structure/01_types.sql
\ir structure/02_tables.sql

\echo '== logic =='
\ir logic/04_triggers.sql

\ir logic/admin/01_user_management.sql
\ir logic/public/02_auth.sql
\ir logic/public/03_views.sql

\ir logic/workers/01_production.sql
\ir logic/workers/02_quality.sql
\ir logic/workers/03_inspector_actions.sql
\ir logic/workers/04_supplies.sql
\ir logic/authorized/01_client_orders.sql

\ir logic/admin/02_analytics_views.sql

\echo '== seed =='
\ir seed/01_seed.sql

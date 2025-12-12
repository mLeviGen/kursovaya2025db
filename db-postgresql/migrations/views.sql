\ir /sql/views/create_products_view.sql
\ir /sql/views/create_orders_view.sql
\ir /sql/views/create_batches_quality_view.sql
\ir /sql/views/create_supplies_view.sql

GRANT SELECT ON public.products_view, public.orders_view, public.batches_quality_view, public.supplies_view
TO cheese_readonly, cheese_readwrite, cheese_app;

\ir /sql/views/create_products_view.sql
\ir /sql/views/create_orders_view.sql
\ir /sql/views/create_batches_quality_view.sql
\ir /sql/views/create_supplies_view.sql
\ir /sql/views/create_order_items_view.sql
\ir /sql/views/create_customer_spending_view.sql
\ir /sql/views/create_product_sales_view.sql
\ir /sql/views/create_recipe_cost_view.sql

GRANT SELECT ON public.products_view, public.orders_view,
  public.batches_quality_view, public.supplies_view, public.order_items_view,
  public.customer_spending_view, public.product_sales_view, public.recipe_cost_view
TO cheese_readonly, cheese_readwrite, cheese_app;

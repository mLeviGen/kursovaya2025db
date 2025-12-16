INSERT INTO auth_user(username, password_hash, user_type, customer_id)
SELECT 'customer1', crypt('customer123', gen_salt('bf')), 'CUSTOMER', 1
WHERE EXISTS (SELECT 1 FROM customer WHERE id = 1)
  AND NOT EXISTS (SELECT 1 FROM auth_user WHERE customer_id = 1);

INSERT INTO auth_user(username, password_hash, user_type)
VALUES ('admin', crypt('admin123', gen_salt('bf')), 'ADMIN')
ON CONFLICT (username) DO NOTHING;

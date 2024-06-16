-- Casting varchars to float
ALTER TABLE order_details
  ALTER COLUMN unit_price TYPE float USING unit_price::double precision,
  ALTER COLUMN quantity TYPE float USING quantity::double precision,
  ALTER COLUMN discount TYPE float USING discount::double precision;
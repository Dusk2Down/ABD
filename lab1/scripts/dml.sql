TRUNCATE TABLE fact_sales, DIMproduct, DIMsupplier, DIMstore, 
    DIMseller, DIMcustomer, DIMbrand, DIMproduct_category, 
    DIMpet_type, DIMdate, DIMcity, DIMstate, DIMcountry, mock_data 
RESTART IDENTITY CASCADE;

SET datestyle = 'ISO, MDY';


COPY mock_data FROM '/data/MOCK_DATA.csv'     DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (1).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (2).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (3).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (4).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (5).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (6).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (7).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (8).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (9).csv' DELIMITER ',' CSV HEADER;


INSERT INTO DIMpet_type (pet_type_name)
SELECT DISTINCT customer_pet_type FROM mock_data 
WHERE customer_pet_type IS NOT NULL AND customer_pet_type != '';

INSERT INTO DIMproduct_category (category_name)
SELECT DISTINCT product_category FROM mock_data 
WHERE product_category IS NOT NULL AND product_category != '';

INSERT INTO DIMbrand (brand_name, material)
SELECT DISTINCT ON (product_brand)
    product_brand, COALESCE(product_material, 'Unknown')
FROM mock_data
WHERE product_brand IS NOT NULL AND product_brand != '';

INSERT INTO DIMdate (full_date, day_num, month_num, year_num, quarter_num, month_name, day_of_week, day_name)
SELECT
    d.full_date,
    EXTRACT(DAY FROM d.full_date)::INT,
    EXTRACT(MONTH FROM d.full_date)::INT,
    EXTRACT(YEAR FROM d.full_date)::INT,
    EXTRACT(QUARTER FROM d.full_date)::INT,
    TO_CHAR(d.full_date, 'Month')::TEXT,
    EXTRACT(ISODOW FROM d.full_date)::INT,
    TO_CHAR(d.full_date, 'Day')::TEXT
FROM (
    SELECT sale_date AS full_date FROM mock_data
    UNION
    SELECT product_release_date FROM mock_data
    UNION
    SELECT product_expiry_date FROM mock_data
) d
WHERE d.full_date IS NOT NULL;



INSERT INTO DIMcountry (country_name)
SELECT customer_country FROM mock_data WHERE customer_country IS NOT NULL AND customer_country != ''
UNION
SELECT seller_country FROM mock_data WHERE seller_country IS NOT NULL AND seller_country != ''
UNION
SELECT store_country FROM mock_data WHERE store_country IS NOT NULL AND store_country != ''
UNION
SELECT supplier_country FROM mock_data WHERE supplier_country IS NOT NULL AND supplier_country != '';


INSERT INTO DIMstate (state_name, country_id)
SELECT DISTINCT
    md.store_state,
    dc.country_id
FROM mock_data md
JOIN DIMcountry dc ON dc.country_name = md.store_country
WHERE md.store_state IS NOT NULL AND md.store_state != '';

INSERT INTO DIMcity (city_name, state_id, country_id)
SELECT DISTINCT
    md.store_city,
    ds.state_id,
    dc.country_id
FROM mock_data md
JOIN DIMcountry dc
    ON dc.country_name = md.store_country
LEFT JOIN DIMstate ds
    ON ds.state_name = md.store_state
   AND ds.country_id = dc.country_id
WHERE md.store_city IS NOT NULL;

INSERT INTO DIMcity (city_name, state_id, country_id)
SELECT DISTINCT
    md.supplier_city,
    NULL::INTEGER,
    dc.country_id
FROM mock_data md
JOIN DIMcountry dc
    ON dc.country_name = md.supplier_country
WHERE NOT EXISTS (
    SELECT 1
    FROM DIMcity c
    WHERE c.city_name = md.supplier_city
      AND c.country_id = dc.country_id
      AND c.state_id IS NULL
);

INSERT INTO DIMcustomer (first_name, last_name, age, email, postal_code, country_id, pet_type_id, pet_name, pet_breed)
SELECT DISTINCT ON (md.customer_email)
    md.customer_first_name,
    md.customer_last_name,
    md.customer_age,
    md.customer_email,
    md.customer_postal_code,
    dc.country_id,
    pt.pet_type_id,
    md.customer_pet_name,
    md.customer_pet_breed
FROM mock_data md
JOIN DIMcountry dc ON dc.country_name = md.customer_country
LEFT JOIN DIMpet_type pt ON pt.pet_type_name = md.customer_pet_type
WHERE md.customer_email IS NOT NULL AND md.customer_email != '';

INSERT INTO DIMseller (first_name, last_name, email, postal_code, country_id)
SELECT DISTINCT ON (md.seller_email)
    md.seller_first_name,
    md.seller_last_name,
    md.seller_email,
    md.seller_postal_code,
    dc.country_id
FROM mock_data md
JOIN DIMcountry dc ON dc.country_name = md.seller_country
WHERE md.seller_email IS NOT NULL AND md.seller_email != '';

INSERT INTO DIMsupplier (supplier_name, contact_name, email, phone, address, city_id, country_id)
SELECT DISTINCT ON (md.supplier_email)
    md.supplier_name,
    md.supplier_contact,
    md.supplier_email,
    md.supplier_phone,
    md.supplier_address,
    dc.city_id,
    dco.country_id
FROM mock_data md
JOIN DIMcountry dco ON dco.country_name = md.supplier_country
JOIN DIMcity dc ON dc.city_name = md.supplier_city 
    AND dc.country_id = dco.country_id
WHERE md.supplier_email IS NOT NULL AND md.supplier_email != ''
ORDER BY md.supplier_email;

INSERT INTO DIMstore (store_name, location, city_id, phone, email)
SELECT DISTINCT
    md.store_name,
    md.store_location,
    dc.city_id,
    md.store_phone,
    md.store_email
FROM mock_data md
JOIN DIMcountry dco ON dco.country_name = md.store_country
LEFT JOIN DIMstate ds ON ds.state_name = md.store_state AND ds.country_id = dco.country_id
JOIN DIMcity dc ON dc.city_name = md.store_city
    AND dc.state_id IS NOT DISTINCT FROM ds.state_id
    AND dc.country_id = dco.country_id
WHERE md.store_name IS NOT NULL AND md.store_name != '';

INSERT INTO DIMproduct (product_name, category_id, weight, color, size, 
    description, rating, reviews, release_date, expiry_date, brand_id, supplier_id)
SELECT DISTINCT
    md.product_name,
    dpc.category_id,
    md.product_weight,
    md.product_color,
    md.product_size,
    md.product_description,
    md.product_rating,
    md.product_reviews,
    md.product_release_date,
    md.product_expiry_date,
    b.brand_id,
    dsu.supplier_id
FROM mock_data md
JOIN DIMproduct_category dpc ON dpc.category_name = md.product_category
JOIN DIMsupplier dsu ON dsu.email = md.supplier_email
LEFT JOIN DIMbrand b ON b.brand_name = md.product_brand
WHERE md.product_name IS NOT NULL AND md.product_name != '';

INSERT INTO fact_sales (customer_id, seller_id, product_id, store_id, sale_date_id, quantity, unit_price, total_price)
SELECT
    dc.customer_id,
    dsel.seller_id,
    dp.product_id,
    dst.store_id,
    dd.date_id,
    md.sale_quantity,
    md.product_price,
    md.sale_total_price
FROM mock_data md
JOIN DIMcustomer dc ON dc.email = md.customer_email
JOIN DIMseller dsel ON dsel.email = md.seller_email
JOIN DIMdate dd ON dd.full_date = md.sale_date
JOIN DIMcountry dco ON dco.country_name = md.store_country
LEFT JOIN DIMstate ds ON ds.state_name = md.store_state AND ds.country_id = dco.country_id
JOIN DIMcity dci ON dci.city_name = md.store_city
    AND dci.state_id IS NOT DISTINCT FROM ds.state_id
    AND dci.country_id = dco.country_id
JOIN DIMstore dst ON dst.store_name = md.store_name
    AND dst.city_id = dci.city_id
    AND dst.location = md.store_location
    AND dst.phone = md.store_phone
    AND dst.email = md.store_email
JOIN DIMproduct_category dpc ON dpc.category_name = md.product_category
JOIN DIMsupplier dsu ON dsu.email = md.supplier_email
JOIN DIMproduct dp ON dp.product_name = md.product_name
    AND dp.category_id = dpc.category_id
    AND dp.supplier_id = dsu.supplier_id
    AND dp.weight = md.product_weight
    AND dp.color = md.product_color
    AND dp.size = md.product_size
WHERE md.sale_date IS NOT NULL 
  AND md.customer_email IS NOT NULL AND md.customer_email != ''
  AND md.seller_email IS NOT NULL AND md.seller_email != '';

SET session_replication_role = 'origin';

CREATE INDEX IF NOT EXISTS idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_seller ON fact_sales(seller_id);
CREATE INDEX IF NOT EXISTS idx_fact_product ON fact_sales(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_store ON fact_sales(store_id);
CREATE INDEX IF NOT EXISTS idx_fact_date ON fact_sales(sale_date_id);
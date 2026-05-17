DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_store CASCADE;
DROP TABLE IF EXISTS dim_seller CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_supplier CASCADE;
DROP TABLE IF EXISTS mock_data CASCADE;


CREATE TABLE mock_data (
    id                      INT,
    customer_first_name     TEXT,
    customer_last_name      TEXT,
    customer_age            INT,
    customer_email          TEXT,
    customer_country        TEXT,
    customer_postal_code    TEXT,
    customer_pet_type       TEXT,
    customer_pet_name       TEXT,
    customer_pet_breed      TEXT,
    seller_first_name       TEXT,
    seller_last_name        TEXT,
    seller_email            TEXT,
    seller_country          TEXT,
    seller_postal_code      TEXT,
    product_name            TEXT,
    product_category        TEXT,
    product_price           NUMERIC(12, 2),
    product_quantity        INT,
    sale_date               DATE,
    sale_customer_id        INT,
    sale_seller_id          INT,
    sale_product_id         INT,
    sale_quantity           INT,
    sale_total_price        NUMERIC(12, 2),
    store_name              TEXT,
    store_location          TEXT,
    store_city              TEXT,
    store_state             TEXT,
    store_country           TEXT,
    store_phone             TEXT,
    store_email             TEXT,
    pet_category            TEXT,
    product_weight          NUMERIC(12, 2),
    product_color           TEXT,
    product_size            TEXT,
    product_brand           TEXT,
    product_material        TEXT,
    product_description     TEXT,
    product_rating          NUMERIC(3, 2),
    product_reviews         INT,
    product_release_date    DATE,
    product_expiry_date     DATE,
    supplier_name           TEXT,
    supplier_contact        TEXT,
    supplier_email          TEXT,
    supplier_phone          TEXT,
    supplier_address        TEXT,
    supplier_city           TEXT,
    supplier_country        TEXT
);


CREATE TABLE dim_customer (
    customer_id         SERIAL PRIMARY KEY,
    first_name          TEXT NOT NULL,
    last_name           TEXT NOT NULL,
    age                 INT,
    email               TEXT NOT NULL UNIQUE,
    country             TEXT,
    postal_code         TEXT,
    pet_type            TEXT,
    pet_name            TEXT,
    pet_breed           TEXT,
    pet_category        TEXT
);


CREATE TABLE dim_seller (
    seller_id           SERIAL PRIMARY KEY,
    first_name          TEXT NOT NULL,
    last_name           TEXT NOT NULL,
    email               TEXT NOT NULL UNIQUE,
    country             TEXT,
    postal_code         TEXT
);


CREATE TABLE dim_store (
    store_id            SERIAL PRIMARY KEY,
    store_name          TEXT NOT NULL,
    store_location      TEXT,
    city                TEXT,
    state               TEXT,
    country             TEXT,
    phone               TEXT,
    email               TEXT UNIQUE
);


CREATE TABLE dim_supplier (
    supplier_id         SERIAL PRIMARY KEY,
    supplier_name       TEXT NOT NULL,
    supplier_contact    TEXT,
    supplier_email      TEXT UNIQUE,
    supplier_phone      TEXT,
    supplier_address    TEXT,
    supplier_city       TEXT,
    supplier_country    TEXT
);


CREATE TABLE dim_product (
    product_id          SERIAL PRIMARY KEY,
    supplier_id         INT,
    product_name        TEXT NOT NULL,
    product_category    TEXT,
    product_price       NUMERIC(12, 2),
    available_quantity  INT,
    product_weight      NUMERIC(12, 2),
    product_color       TEXT,
    product_size        TEXT,
    product_brand       TEXT,
    product_material    TEXT,
    product_description TEXT,
    product_rating      NUMERIC(3, 2),
    product_reviews     INT,
    product_release_date DATE,
    product_expiry_date DATE,
    
    CONSTRAINT fk_dim_product_supplier
        FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id)
);


CREATE TABLE dim_date (
    date_id             SERIAL PRIMARY KEY,
    full_date           DATE NOT NULL UNIQUE,
    year_num            INT NOT NULL,
    month_num           INT NOT NULL,
    month_name          TEXT NOT NULL,
    quarter_num         INT NOT NULL,
    day_num             INT NOT NULL,
    day_name            TEXT NOT NULL,
    week_num            INT,
    is_weekend          BOOLEAN
);


CREATE TABLE fact_sales (
    fact_sale_id        SERIAL PRIMARY KEY,
    
    source_row_id       INT,
    
    customer_id         INT NOT NULL,
    seller_id           INT NOT NULL,
    store_id            INT NOT NULL,
    product_id          INT NOT NULL,
    date_id             INT NOT NULL,
    
    sale_customer_source_id INT,
    sale_seller_source_id   INT,
    sale_product_source_id  INT,
    
    sale_quantity       INT NOT NULL,
    sale_total_price    NUMERIC(12, 2) NOT NULL,
    
    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_fact_sales_seller
        FOREIGN KEY (seller_id) REFERENCES dim_seller(seller_id),
    CONSTRAINT fk_fact_sales_store
        FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    CONSTRAINT fk_fact_sales_date
        FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
);


CREATE INDEX idx_fact_sales_customer_id ON fact_sales(customer_id);
CREATE INDEX idx_fact_sales_seller_id ON fact_sales(seller_id);
CREATE INDEX idx_fact_sales_store_id ON fact_sales(store_id);
CREATE INDEX idx_fact_sales_product_id ON fact_sales(product_id);
CREATE INDEX idx_fact_sales_date_id ON fact_sales(date_id);
CREATE INDEX idx_fact_sales_revenue ON fact_sales(sale_total_price, date_id);
CREATE INDEX idx_fact_sales_product_date ON fact_sales(product_id, date_id);


TRUNCATE TABLE mock_data RESTART IDENTITY CASCADE;

COPY mock_data FROM '/data/MOCK_DATA.csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (1).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (2).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (3).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (4).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (5).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (6).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (7).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (8).csv' DELIMITER ',' CSV HEADER;
COPY mock_data FROM '/data/MOCK_DATA (9).csv' DELIMITER ',' CSV HEADER;


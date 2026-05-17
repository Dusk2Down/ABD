DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS DIMproduct CASCADE;
DROP TABLE IF EXISTS DIMsupplier CASCADE;
DROP TABLE IF EXISTS DIMstore CASCADE;
DROP TABLE IF EXISTS DIMseller CASCADE;
DROP TABLE IF EXISTS DIMcustomer CASCADE;
DROP TABLE IF EXISTS DIMbrand CASCADE;
DROP TABLE IF EXISTS DIMproduct_category CASCADE;
DROP TABLE IF EXISTS DIMpet_type CASCADE;
DROP TABLE IF EXISTS DIMdate CASCADE;
DROP TABLE IF EXISTS DIMcity CASCADE;
DROP TABLE IF EXISTS DIMstate CASCADE;
DROP TABLE IF EXISTS DIMcountry CASCADE;
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
    product_price           NUMERIC(12,2),
    product_quantity        INT,
    sale_date               DATE,
    sale_customer_id        INT,
    sale_seller_id          INT,
    sale_product_id         INT,
    sale_quantity           INT,
    sale_total_price        NUMERIC(12,2),
    store_name              TEXT,
    store_location          TEXT,
    store_city              TEXT,
    store_state             TEXT,
    store_country           TEXT,
    store_phone             TEXT,
    store_email             TEXT,
    pet_category            TEXT,
    product_weight          NUMERIC(12,2),
    product_color           TEXT,
    product_size            TEXT,
    product_brand           TEXT,
    product_material        TEXT,
    product_description     TEXT,
    product_rating          NUMERIC(3,2),
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

CREATE TABLE DIMpet_type (
    pet_type_id     SERIAL PRIMARY KEY,
    pet_type_name   TEXT NOT NULL UNIQUE
);

CREATE TABLE DIMproduct_category (
    category_id     SERIAL PRIMARY KEY,
    category_name   TEXT NOT NULL UNIQUE
);

CREATE TABLE DIMbrand (
    brand_id    SERIAL PRIMARY KEY,
    brand_name  TEXT NOT NULL UNIQUE,
    material    TEXT
);

CREATE TABLE DIMdate (
    date_id         SERIAL PRIMARY KEY,
    full_date       DATE NOT NULL UNIQUE,
    day_num         INT NOT NULL,
    month_num       INT NOT NULL,
    year_num        INT NOT NULL,
    quarter_num     INT NOT NULL,
    month_name      TEXT NOT NULL,
    day_of_week     INT NOT NULL,
    day_name        TEXT NOT NULL
);

CREATE TABLE DIMcountry (
    country_id      SERIAL PRIMARY KEY,
    country_name    TEXT NOT NULL UNIQUE
);

CREATE TABLE DIMstate (
    state_id        SERIAL PRIMARY KEY,
    state_name      TEXT NOT NULL,
    country_id      INT NOT NULL REFERENCES DIMcountry(country_id),
    CONSTRAINT uq_state UNIQUE (state_name, country_id)
);

CREATE TABLE DIMcity (
    city_id         SERIAL PRIMARY KEY,
    city_name       TEXT NOT NULL,
    state_id        INT REFERENCES DIMstate(state_id),
    country_id      INT NOT NULL REFERENCES DIMcountry(country_id),
    CONSTRAINT uq_city UNIQUE (city_name, state_id, country_id)
);

CREATE TABLE DIMcustomer (
    customer_id     SERIAL PRIMARY KEY,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    age             INT,
    email           TEXT NOT NULL UNIQUE,
    postal_code     TEXT,
    country_id      INT REFERENCES DIMcountry(country_id),
    pet_type_id     INT REFERENCES DIMpet_type(pet_type_id),
    pet_name        TEXT,
    pet_breed       TEXT
);


CREATE TABLE DIMseller (
    seller_id       SERIAL PRIMARY KEY,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    postal_code     TEXT,
    country_id      INT REFERENCES DIMcountry(country_id)
);


CREATE TABLE DIMsupplier (
    supplier_id     SERIAL PRIMARY KEY,
    supplier_name   TEXT NOT NULL,
    contact_name    TEXT,
    email           TEXT UNIQUE,
    phone           TEXT,
    address         TEXT,
    city_id         INT REFERENCES DIMcity(city_id),
    country_id      INT REFERENCES DIMcountry(country_id)
);

CREATE TABLE DIMstore (
    store_id        SERIAL PRIMARY KEY,
    store_name      TEXT NOT NULL,
    location        TEXT,
    city_id         INT REFERENCES DIMcity(city_id),
    phone           TEXT,
    email           TEXT UNIQUE,
    CONSTRAINT uq_store UNIQUE (store_name, location, city_id)
);

CREATE TABLE DIMproduct (
    product_id      SERIAL PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category_id     INT REFERENCES DIMproduct_category(category_id),
    weight          NUMERIC(12,2),
    color           TEXT,
    size            TEXT,
    description     TEXT,
    rating          NUMERIC(3,2),
    reviews         INT,
    release_date    DATE,
    expiry_date     DATE,
    brand_id        INT REFERENCES DIMbrand(brand_id),
    supplier_id     INT REFERENCES DIMsupplier(supplier_id),
    CONSTRAINT uq_product UNIQUE (product_name, category_id, brand_id, weight, color, size)
);

CREATE TABLE fact_sales (
    sale_id         SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES DIMcustomer(customer_id),
    seller_id       INT NOT NULL REFERENCES DIMseller(seller_id),
    product_id      INT NOT NULL REFERENCES DIMproduct(product_id),
    store_id        INT NOT NULL REFERENCES DIMstore(store_id),
    sale_date_id    INT NOT NULL REFERENCES DIMdate(date_id),
    quantity        INT NOT NULL,
    unit_price      NUMERIC(12,2) NOT NULL,
    total_price     NUMERIC(12,2) NOT NULL
);

CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_seller   ON fact_sales(seller_id);
CREATE INDEX idx_fact_product  ON fact_sales(product_id);
CREATE INDEX idx_fact_store    ON fact_sales(store_id);
CREATE INDEX idx_fact_date     ON fact_sales(sale_date_id);  
SET session_replication_role = 'replica';
SET synchronous_commit = off;
SET maintenance_work_mem = '1GB';
SET work_mem = '512MB';
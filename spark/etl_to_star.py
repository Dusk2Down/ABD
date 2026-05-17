from pyspark.sql import SparkSession
from pyspark.sql.functions import col, dayofmonth, month, year, quarter, date_format

def main():
    spark = SparkSession.builder \
        .appName("ETL Mock Data To Star Schema") \
        .config("spark.sql.legacy.timeParserPolicy", "LEGACY") \
        .getOrCreate()
    
    jdbc_url = "jdbc:postgresql://postgres:5432/bigdata_lab2"
    jdbc_props = {
        "user": "postgres",
        "password": "postgres",
        "driver": "org.postgresql.Driver"
    }
    
    mock_data = spark.read.jdbc(url=jdbc_url, table="mock_data", properties=jdbc_props)
    
    dim_customer = (
        mock_data
        .select(
            col("customer_first_name").alias("first_name"),
            col("customer_last_name").alias("last_name"),
            col("customer_age").alias("age"),
            col("customer_email").alias("email"),
            col("customer_country").alias("country"),
            col("customer_postal_code").alias("postal_code"),
            col("customer_pet_type").alias("pet_type"),
            col("customer_pet_name").alias("pet_name"),
            col("customer_pet_breed").alias("pet_breed"),
            col("pet_category").alias("pet_category")
        )
        .dropDuplicates(["email"])
    )
    
    dim_seller = (
        mock_data
        .select(
            col("seller_first_name").alias("first_name"),
            col("seller_last_name").alias("last_name"),
            col("seller_email").alias("email"),
            col("seller_country").alias("country"),
            col("seller_postal_code").alias("postal_code")
        )
        .dropDuplicates(["email"])
    )
    
    dim_store = (
        mock_data
        .select(
            col("store_name").alias("store_name"),
            col("store_location").alias("store_location"),
            col("store_city").alias("city"),
            col("store_state").alias("state"),
            col("store_country").alias("country"),
            col("store_phone").alias("phone"),
            col("store_email").alias("email")
        )
        .dropDuplicates(["store_name", "email"])
    )
    
    dim_supplier = (
        mock_data
        .select(
            col("supplier_name").alias("supplier_name"),
            col("supplier_contact").alias("supplier_contact"),
            col("supplier_email").alias("supplier_email"),
            col("supplier_phone").alias("supplier_phone"),
            col("supplier_address").alias("supplier_address"),
            col("supplier_city").alias("supplier_city"),
            col("supplier_country").alias("supplier_country")
        )
        .dropDuplicates(["supplier_email"])
    )
    
    dim_supplier.write.jdbc(url=jdbc_url, table="dim_supplier", mode="append", properties=jdbc_props)
    dim_supplier_db = spark.read.jdbc(url=jdbc_url, table="dim_supplier", properties=jdbc_props)
    
    dim_product = (
        mock_data.alias("m")
        .join(
            dim_supplier_db.alias("s"),
            col("m.supplier_email") == col("s.supplier_email"),
            "left"
        )
        .select(
            col("s.supplier_id").alias("supplier_id"),
            col("m.product_name").alias("product_name"),
            col("m.product_category").alias("product_category"),
            col("m.product_price").alias("product_price"),
            col("m.product_quantity").alias("available_quantity"),
            col("m.product_weight").alias("product_weight"),
            col("m.product_color").alias("product_color"),
            col("m.product_size").alias("product_size"),
            col("m.product_brand").alias("product_brand"),
            col("m.product_material").alias("product_material"),
            col("m.product_description").alias("product_description"),
            col("m.product_rating").alias("product_rating"),
            col("m.product_reviews").alias("product_reviews"),
            col("m.product_release_date").alias("product_release_date"),
            col("m.product_expiry_date").alias("product_expiry_date")
        )
        .dropDuplicates(["product_name", "supplier_id", "product_brand", "product_color", "product_size"])
    )
    
    dim_date = (
        mock_data
        .select(col("sale_date").alias("full_date"))
        .dropDuplicates(["full_date"])
        .withColumn("day_num", dayofmonth(col("full_date")))
        .withColumn("month_num", month(col("full_date")))
        .withColumn("year_num", year(col("full_date")))
        .withColumn("quarter_num", quarter(col("full_date")))
        .withColumn("month_name", date_format(col("full_date"), "MMMM"))
        .withColumn("day_name", date_format(col("full_date"), "EEEE"))
    )
    
    dim_customer.write.jdbc(url=jdbc_url, table="dim_customer", mode="append", properties=jdbc_props)
    dim_seller.write.jdbc(url=jdbc_url, table="dim_seller", mode="append", properties=jdbc_props)
    dim_store.write.jdbc(url=jdbc_url, table="dim_store", mode="append", properties=jdbc_props)
    dim_product.write.jdbc(url=jdbc_url, table="dim_product", mode="append", properties=jdbc_props)
    dim_date.write.jdbc(url=jdbc_url, table="dim_date", mode="append", properties=jdbc_props)
    
    dim_customer_db = spark.read.jdbc(url=jdbc_url, table="dim_customer", properties=jdbc_props)
    dim_seller_db = spark.read.jdbc(url=jdbc_url, table="dim_seller", properties=jdbc_props)
    dim_store_db = spark.read.jdbc(url=jdbc_url, table="dim_store", properties=jdbc_props)
    dim_product_db = spark.read.jdbc(url=jdbc_url, table="dim_product", properties=jdbc_props)
    dim_date_db = spark.read.jdbc(url=jdbc_url, table="dim_date", properties=jdbc_props)
    
    fact_sales = (
        mock_data.alias("m")
        .join(dim_customer_db.alias("c"), col("m.customer_email") == col("c.email"), "inner")
        .join(dim_seller_db.alias("s"), col("m.seller_email") == col("s.email"), "inner")
        .join(dim_store_db.alias("st"), (col("m.store_name") == col("st.store_name")) & (col("m.store_email") == col("st.email")), "inner")
        .join(dim_supplier_db.alias("sup"), col("m.supplier_email") == col("sup.supplier_email"), "left")
        .join(dim_product_db.alias("p"), (col("m.product_name") == col("p.product_name")) & (col("sup.supplier_id") == col("p.supplier_id")), "inner")
        .join(dim_date_db.alias("d"), col("m.sale_date") == col("d.full_date"), "inner")
        .select(
            col("m.id").alias("source_row_id"),
            col("c.customer_id").alias("customer_id"),
            col("s.seller_id").alias("seller_id"),
            col("st.store_id").alias("store_id"),
            col("p.product_id").alias("product_id"),
            col("d.date_id").alias("date_id"),
            col("m.sale_customer_id").alias("sale_customer_source_id"),
            col("m.sale_seller_id").alias("sale_seller_source_id"),
            col("m.sale_product_id").alias("sale_product_source_id"),
            col("m.sale_quantity").alias("sale_quantity"),
            col("m.sale_total_price").alias("sale_total_price")
        )
    )
    
    fact_sales.write.jdbc(url=jdbc_url, table="fact_sales", mode="append", properties=jdbc_props)
    spark.stop()

if __name__ == "__main__":
    main()
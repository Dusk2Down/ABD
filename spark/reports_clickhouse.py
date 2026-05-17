from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, sum as _sum, avg, count, desc, round as _round
)


def main():
    spark = (
        SparkSession.builder
        .appName("Build ClickHouse Reports")
        .getOrCreate()
    )

    postgres_url = "jdbc:postgresql://postgres:5432/bigdata_lab2"
    postgres_props = {
        "user": "postgres",
        "password": "postgres",
        "driver": "org.postgresql.Driver"
    }

    clickhouse_url = "jdbc:clickhouse://clickhouse:8123/bigdata_lab2?compress=0"
    clickhouse_props = {
        "driver": "com.clickhouse.jdbc.ClickHouseDriver",
        "user": "default",
        "password": "default",
    }

    
    fact_sales = spark.read.jdbc(postgres_url, "fact_sales", properties=postgres_props)
    dim_customer = spark.read.jdbc(postgres_url, "dim_customer", properties=postgres_props)
    dim_seller = spark.read.jdbc(postgres_url, "dim_seller", properties=postgres_props)
    dim_store = spark.read.jdbc(postgres_url, "dim_store", properties=postgres_props)
    dim_supplier = spark.read.jdbc(postgres_url, "dim_supplier", properties=postgres_props)
    dim_product = spark.read.jdbc(postgres_url, "dim_product", properties=postgres_props)
    dim_date = spark.read.jdbc(postgres_url, "dim_date", properties=postgres_props)
    
    
    sales_df = (
        fact_sales.alias("f")
        .join(dim_customer.alias("c"), col("f.customer_id") == col("c.customer_id"), "inner")
        .join(dim_seller.alias("se"), col("f.seller_id") == col("se.seller_id"), "inner")
        .join(dim_store.alias("st"), col("f.store_id") == col("st.store_id"), "inner")
        .join(dim_product.alias("p"), col("f.product_id") == col("p.product_id"), "inner")
        .join(dim_supplier.alias("su"), col("p.supplier_id") == col("su.supplier_id"), "left")
        .join(dim_date.alias("d"), col("f.date_id") == col("d.date_id"), "inner")
    )

    
    report_product_sales = (
        sales_df
        .groupBy(
            col("p.product_id"),
            col("p.product_name"),
            col("p.product_category"),
            col("p.product_rating"),
            col("p.product_reviews")
        )
        .agg(
            _sum("f.sale_quantity").alias("total_quantity_sold"),
            _sum("f.sale_total_price").alias("total_revenue"),
            avg("p.product_rating").alias("avg_rating"),
            _sum("p.product_reviews").alias("total_reviews")
        )
        .withColumn("avg_rating", _round(col("avg_rating"), 2))
        .orderBy(desc("total_revenue"))
    )
    
    report_product_sales.write \
        .option("createTableOptions", "ENGINE = MergeTree() ORDER BY product_id") \
        .mode("append") \
        .jdbc(clickhouse_url, "product_sales_report", properties=clickhouse_props)
    report_customer_sales = (
        sales_df
        .groupBy(
            col("c.customer_id"),
            col("c.first_name"),
            col("c.last_name"),
            col("c.country")
        )
        .agg(
            count("f.fact_sale_id").alias("total_orders"),
            _sum("f.sale_total_price").alias("total_spent"),
            avg("f.sale_total_price").alias("avg_check")
        )
        .withColumn("avg_check", _round(col("avg_check"), 2))
        .orderBy(desc("total_spent"))
    )
    
    report_customer_sales.write \
        .option("createTableOptions", "ENGINE = MergeTree() ORDER BY customer_id") \
        .mode("append") \
        .jdbc(clickhouse_url, "customer_sales_report", properties=clickhouse_props)
    
    report_time_sales = (
        sales_df
        .groupBy(
            col("d.year_num"),
            col("d.month_num"),
            col("d.month_name")
        )
        .agg(
            count("f.fact_sale_id").alias("total_orders"),
            _sum("f.sale_quantity").alias("total_quantity"),
            _sum("f.sale_total_price").alias("total_revenue"),
            avg("f.sale_total_price").alias("avg_order_value")
        )
        .withColumn("avg_order_value", _round(col("avg_order_value"), 2))
        .orderBy("year_num", "month_num")
    )
    
    report_time_sales.write \
        .option("createTableOptions", "ENGINE = MergeTree() ORDER BY (year_num, month_num)") \
        .mode("append") \
        .jdbc(clickhouse_url, "time_sales_report", properties=clickhouse_props)
    
    report_store_sales = (
        sales_df
        .groupBy(
            col("st.store_id"),
            col("st.store_name"),
            col("st.city"),
            col("st.country")
        )
        .agg(
            count("f.fact_sale_id").alias("total_orders"),
            _sum("f.sale_total_price").alias("total_revenue"),
            avg("f.sale_total_price").alias("avg_check")
        )
        .withColumn("avg_check", _round(col("avg_check"), 2))
        .orderBy(desc("total_revenue"))
    )
    
    report_store_sales.write \
        .option("createTableOptions", "ENGINE = MergeTree() ORDER BY store_id") \
        .mode("append") \
        .jdbc(clickhouse_url, "store_sales_report", properties=clickhouse_props)
    
    report_supplier_sales = (
        sales_df
        .groupBy(
            col("su.supplier_id"),
            col("su.supplier_name"),
            col("su.supplier_country")
        )
        .agg(
            _sum("f.sale_total_price").alias("total_revenue"),
            avg("p.product_price").alias("avg_product_price"),
            _sum("f.sale_quantity").alias("total_quantity_sold")
        )
        .withColumn("avg_product_price", _round(col("avg_product_price"), 2))
        .orderBy(desc("total_revenue"))
    )
    
    report_supplier_sales.write \
        .option("createTableOptions", "ENGINE = MergeTree() ORDER BY supplier_id") \
        .mode("append") \
        .jdbc(clickhouse_url, "supplier_sales_report", properties=clickhouse_props)
    report_product_quality = (
        sales_df
        .groupBy(
            col("p.product_id"),
            col("p.product_name"),
            col("p.product_rating"),
            col("p.product_reviews")
        )
        .agg(
            _sum("f.sale_quantity").alias("total_quantity_sold"),
            _sum("f.sale_total_price").alias("total_revenue"),
            count("f.fact_sale_id").alias("times_purchased")
        )
        .orderBy(desc("p.product_rating"))
    )
    
    report_product_quality.write \
        .option("createTableOptions", "ENGINE = MergeTree() ORDER BY product_id") \
        .mode("append") \
        .jdbc(clickhouse_url, "product_quality_report", properties=clickhouse_props)

    spark.stop()


if __name__ == "__main__":
    main()
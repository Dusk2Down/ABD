## Запуск ETL 
docker exec -it bigdata_lab2_spark /usr/local/spark-3.4.0-bin-hadoop3/bin/spark-submit \
  --jars /home/jovyan/jars/postgresql-42.7.3.jar \
  /home/jovyan/spark/etl_to_star.py

## ЗАпуск создания отчетов
docker exec -it bigdata_lab2_spark /usr/local/spark-3.4.0-bin-hadoop3/bin/spark-submit \
  --jars /home/jovyan/jars/postgresql-42.7.3.jar,/home/jovyan/jars/clickhouse-jdbc-0.6.3-shaded.jar \
  /home/jovyan/spark/reports_clickhouse.py

## Проверка создания отчетов
docker exec -it bigdata_lab2_clickhouse clickhouse-client --query "
SELECT 'product_sales_report' as report_name, count(*) as rows FROM bigdata_lab2.product_sales_report
UNION ALL
SELECT 'customer_sales_report', count(*) FROM bigdata_lab2.customer_sales_report
UNION ALL
SELECT 'time_sales_report', count(*) FROM bigdata_lab2.time_sales_report
UNION ALL
SELECT 'store_sales_report', count(*) FROM bigdata_lab2.store_sales_report
UNION ALL
SELECT 'supplier_sales_report', count(*) FROM bigdata_lab2.supplier_sales_report
UNION ALL
SELECT 'product_quality_report', count(*) FROM bigdata_lab2.product_quality_report;
"

# Топ-10 продуктов по выручке
docker exec -it bigdata_lab2_clickhouse clickhouse-client --query "
SELECT product_name, total_revenue, total_quantity_sold 
FROM bigdata_lab2.product_sales_report 
ORDER BY total_revenue DESC 
LIMIT 10;"
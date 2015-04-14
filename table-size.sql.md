# Размер таблиц в базе данных с упорядочиванием по размеру

```
SELECT table_name, CONCAT(ROUND(table_rows/1000000,2),'M') AS `rows`,
CONCAT(ROUND(data_length/(1024*1024),2),'M') AS `DATA`,
CONCAT(ROUND(index_length/(1024*1024),2),'M') AS `idx`,
CONCAT(ROUND((data_length+index_length)/(1024*1024),2),'M') AS `total_size`,
ROUND(index_length/data_length,2) AS `idxfrac`
FROM information_schema.TABLES WHERE `table_schema` = 'data_base'
ORDER BY data_length+index_length DESC LIMIT 10;
```
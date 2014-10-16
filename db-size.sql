-- Размер баз данных
SELECT table_schema AS 'database', 
ROUND( SUM( data_length + index_length ) / ( 1024 *1024 ) , 2 ) AS `size`
FROM information_schema.TABLES
WHERE ENGINE=('MyISAM' || 'InnoDB') 
GROUP BY table_schema;
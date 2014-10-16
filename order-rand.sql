-- Выбор случайных записей (случайная сортировка)
-- Don't use ORDER BY RAND() if you have > ~2K records [http://www.debianhelp.co.uk/mysqltips.htm]

-- Bad solution
SELECT * FROM news ORDER BY RAND() LIMIT 1;

-- Better
SET @random = ROUND(RAND() * (SELECT COUNT(*) FROM news));
SET @s = CONCAT('SELECT * FROM news LIMIT ', @random, ', 1');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Another way
PREPARE stmt FROM 'SELECT * FROM news LIMIT ?, 1';
SET @random = ROUND(RAND() * (SELECT COUNT(*) FROM news));
EXECUTE stmt USING @random;
DEALLOCATE PREPARE stmt;

-- With PHP
SELECT ROUND(RAND() * (SELECT COUNT(*) FROM news)) AS `random`;
SELECT * FROM news LIMIT -- <?php echo $random.' ,1' ?>

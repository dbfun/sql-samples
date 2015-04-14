# Хранимая процедура для вставки в несколько таблиц одним запросом (нормализация)

```
-- TRUNCATE TABLE wdi
-- TRUNCATE TABLE wdi_p

DELIMITER $$

DROP PROCEDURE IF EXISTS `WDI_INSERT`$$

CREATE PROCEDURE `WDI_INSERT` (name VARCHAR(64), branch VARCHAR(32), sha1 CHAR(40))
  BEGIN
    SET @name = name;
    SET @branch = branch;
    SET @sha1 = sha1;

    PREPARE stmt1 FROM 'SET @pid = (SELECT `project_id` FROM `wdi_p` WHERE `name` = ? LIMIT 1)';
    PREPARE stmt2 FROM 'INSERT INTO `wdi` (`project_id`, `branch`, `sha1`) VALUES (?, ?, ?)';

    INSERT IGNORE INTO `wdi_p` (`name`) VALUES (@name);

    EXECUTE stmt1 USING @name;
    EXECUTE stmt2 USING @pid, @branch, @sha1;

    DEALLOCATE PREPARE stmt1;
    DEALLOCATE PREPARE stmt2;
    SELECT @pid;
  END;
$$

DELIMITER ;
```
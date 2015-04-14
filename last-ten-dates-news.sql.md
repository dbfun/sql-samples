# Выборка последних десяти дат, по которым есть новости

Таблица `news` должна содержать дату `idate` INT(11) UNSIGNED NOT NULL - время в формате UNIXTIME.

UNIX_TIMESTAMP() следует изменить так, чтобы отсчет был от начала текущего дня (00:00:00), а не текущего времени.
Например, `UNIX_TIMESTAMP(CURDATE())`. То есть дата `2000-01-01 17:59:59` не допустима, `2000-01-01 00:00:00` - допустима.

В примерах используется `UNIX_TIMESTAMP()`.

Сравнительные тесты проведены на 270 тыс реальных записей.

## Решение 1. "В лоб"

2.5 сек без индексов, 0.7 сек - с индексами:

```
SELECT CAST(FROM_UNIXTIME(`idate`) AS DATE)
FROM `news`
WHERE `idate` < UNIX_TIMESTAMP()
GROUP BY CAST(FROM_UNIXTIME(`idate`) AS DATE)
ORDER BY `idate` DESC LIMIT 10;
```

## Решение 2. "Преобразование типов"

Преобразовать `idate` в тип `DATE` (30 сек, с индексом - моментально) и считать что требуемые даты не старше 30 дней.

```
SELECT `idate` FROM `news`
WHERE `idate` BETWEEN ADDDATE(NOW(), INTERVAL -30 DAY) AND NOW()
GROUP BY `idate` ORDER BY `idate` DESC LIMIT 10;
```

## Решение 3. "Ограниченная выборка с подзапросами"

Сделать 30 однотипных подзапросов на каждый день, и на php выбрать требуемые столбцы. В примере - три:

```
SELECT
(SELECT CAST(FROM_UNIXTIME(`idate`) AS DATE) FROM `news` WHERE `idate` BETWEEN UNIX_TIMESTAMP(ADDDATE(CURDATE(), INTERVAL -1 DAY)) AND UNIX_TIMESTAMP(CURDATE()) LIMIT 1) AS `date1`,
(SELECT CAST(FROM_UNIXTIME(`idate`) AS DATE) FROM `news` WHERE `idate` BETWEEN UNIX_TIMESTAMP(ADDDATE(CURDATE(), INTERVAL -2 DAY)) AND UNIX_TIMESTAMP(ADDDATE(CURDATE(), INTERVAL -1 DAY)) LIMIT 1) AS `date2`,
(SELECT CAST(FROM_UNIXTIME(`idate`) AS DATE) FROM `news` WHERE `idate` BETWEEN UNIX_TIMESTAMP(ADDDATE(CURDATE(), INTERVAL -3 DAY)) AND UNIX_TIMESTAMP(ADDDATE(CURDATE(), INTERVAL -2 DAY)) LIMIT 1) AS `date3`;
```

## Решение 4. "Сводная таблица"

Данные в сводной таблице `news_dates` могут устаревать при изменениях дат новостей (перенос новости в прошлое, например).

Не учитывается то, что новости могут быть заранее распределены на будущее время.

Рекомендуется оставить обновление триггерами с переодической актуализацией дат.

```
DROP TABLE IF EXISTS `news_dates`;
CREATE TABLE `news_dates` (
  `id` TINYINT(3) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATE NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_date` (`date`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
```

Заполнение фиктивными датами:

```
INSERT INTO `news_dates` (`date`) VALUES ('1900-01-01'), ('1900-02-01'), ('1900-03-01'), ('1900-04-01'), ('1900-05-01'), ('1900-06-01'), ('1900-07-01'), ('1900-08-01'), ('1900-09-01'), ('1900-10-01');
```

Триггер на добавление новости:

```
DELIMITER $$

DROP TRIGGER IF EXISTS `news_after_insert`$$

CREATE TRIGGER `news_after_insert` AFTER INSERT ON `news`
  FOR EACH ROW BEGIN
    UPDATE IGNORE `news_dates` SET `date` = CAST(FROM_UNIXTIME(NEW.idate) AS DATE) WHERE NEW.idate < UNIX_TIMESTAMP() AND `date` <= CAST(FROM_UNIXTIME(NEW.idate) AS DATE) ORDER BY `date` ASC LIMIT 1;
  END;
$$

DELIMITER ;
```

Триггер на изменение даты новости:

```
DELIMITER $$

DROP TRIGGER IF EXISTS `news_after_update`$$

CREATE TRIGGER `news_after_update` AFTER UPDATE ON `news`
  FOR EACH ROW BEGIN
    UPDATE IGNORE `news_dates` SET `date` = CAST(FROM_UNIXTIME(NEW.idate) AS DATE) WHERE NEW.idate < UNIX_TIMESTAMP() AND `date` <= CAST(FROM_UNIXTIME(NEW.idate) AS DATE) ORDER BY `date` ASC LIMIT 1;
  END;
$$

DELIMITER ;
```

Обновление сводной таблицы (осторожно, медленно!, возможны неточности) для теста:

```
UPDATE `news` SET `idate` = `idate` - 1;
UPDATE `news` SET `idate` = `idate` + 1;
```
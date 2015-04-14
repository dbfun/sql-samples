# Задача: График дежурств работников.

Каждый выходной день дежурят 4 человека из 30-ти.

* Все должны отдежурить примерно одинаковое количество раз
* Нельзя дежурить два раза подряд
* Некоторые не любят дежурить по воскресениям, или по субботам

# Решение

Каждая итерация будет добавлять новую дату с расписанием (дата указывается в запросе).

Будем выбирать случайно 4 записи (работника) из 30, кроме тех, кто подпадает под условия:

* "два раза подряд"
* "не люблю в этот день"

## Модель данных

### Таблица рабочих

```
CREATE TABLE `users` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL DEFAULT '',
  `exclude_sat` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `exclude_sun` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=INNODB;
```

Данные рабочих:
```
INSERT INTO `users` (`name`, `exclude_sat`, `exclude_sun`) VALUES
('Александр',0,0),
('Анатолий',0,0),
('Андрей',0,0),
('Анна',0,0),
('Борис',0,0),
('Василий',0,1),
('Владимир',0,1),
('Вячеслав',0,1),
('Глеб',0,0),
('Григорий',0,0),
('Дарья',0,0),
('Дмитрий',0,0),
('Иван',0,0),
('Игорь',0,0),
('Ирина',0,0),
('Кирилл',0,0),
('Кристина',0,0),
('Ксения',0,0),
('Людмила',0,0),
('Максим',0,0),
('Надежда',0,0),
('Не работаю в выходные',1,1),
('Никита',0,0),
('Ольга',0,0),
('Павел',0,0),
('Полина',0,0),
('Сергей',1,0),
('Спартак',1,0),
('Степан',1,0),
('Яна',0,0);
```

* `exclude_sat` - рабочий не дежурит в Субботу (имена, начинающиеся на "С").
* `exclude_sun` - рабочий не дежурит в Воскресенье (имена, начинающиеся на "В").

### Таблица расписания

```
CREATE TABLE `schedule` (
  `date` DATE NOT NULL,
  `user_id` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`date`,`user_id`)
) ENGINE=INNODB;
```

## Условие "два раза подряд"

Необходимо выбрать всех рабочих за две ближайшие даты - следующую и предыдущую относительно данной. Их в дальнейшем необходимо исключить.

Будем составлять расписания на `18 апреля 2015 (суббота)`.

Выбираем предыдущую дату:

```
SELECT MAX(`date`) AS `prev_date` FROM `schedule` WHERE `date` < '2015-04-18';
```

Выбираем следущую дату:

```
SELECT MIN(`date`) AS `next_date` FROM `schedule` WHERE `date` > '2015-04-18';
```

В итоге, выбираем рабочих, дежуривших до и после (два предыдущих выражения - в подзапрос):

```
SELECT `user_id` FROM `schedule` WHERE `date` IN (
  SELECT MAX(`date`) AS `prev_date` FROM `schedule` WHERE `date` < '2015-04-18'
  UNION ALL
  SELECT MIN(`date`) AS `next_date` FROM `schedule` WHERE `date` > '2015-04-18'
);
```

## Условие "не люблю в этот день"

Является ли дата субботой? Нумерация дней недели с понедельника, его индекс = 0:

```
SELECT WEEKDAY('2015-04-18') = 5;
```

Является ли дата воскресеньем?

```
SELECT WEEKDAY('2015-04-18') = 6;
```

Кто может дежурить `18 апреля 2015 (суббота)`? Здесь две проверки, так как заранее не известно, какой это день недели.

```
SELECT *
FROM `users`
WHERE
(exclude_sat = 0 OR WEEKDAY('2015-04-18') <> 5) AND
(exclude_sun = 0 OR WEEKDAY('2015-04-18') <> 6);
```

## Кто может дежурить?

Кто может дежурить `18 апреля 2015 (суббота)`, и не дежурил до этой даты, и не стоит в расписании после:

```
SELECT *
FROM `users`
WHERE
(exclude_sat = 0 OR WEEKDAY('2015-04-18') <> 5) AND
(exclude_sun = 0 OR WEEKDAY('2015-04-18') <> 6) AND
id NOT IN (
  SELECT `user_id` FROM `schedule` WHERE `date` IN (
    SELECT MAX(`date`) AS `prev_date` FROM `schedule` WHERE `date` < '2015-04-18'
    UNION ALL
    SELECT MIN(`date`) AS `next_date` FROM `schedule` WHERE `date` > '2015-04-18'
  )
);
```

Если дописать `ORDER BY RAND() LIMIT 4`, то получим рабочих, которых возможно вставить. Но такая простота обманчива.
В расписании на 1000 выходных выяснилось, что рабочие, предпочиающие не выходить в один из дней, работают в два раза меньше.
Это происходит от того, что `ORDER BY RAND() LIMIT 4` работает не по генеральной совокупности, а уже по выборке.

Присоединять таблицу с расписанием для дополнительной сортировки по количеству "отработанных" дней обходится слишком накладно по времени (30 секунд).

## Уравновешивание шансов дежурить

Добавим в таблицу рабочих количество "отработанных" дней и сделаем это количество актуальным (по расписанию):

```
ALTER TABLE `users` ADD `num_work_days` INT(11) UNSIGNED NOT NULL DEFAULT '0';

UPDATE `users`
JOIN (
  SELECT COUNT(*) AS `count`, user_id
  FROM `schedule`
  GROUP BY user_id
) AS `aggregated`
ON aggregated.user_id = users.id
SET num_work_days = aggregated.count;
```

Теперь возможно вставить в таблицу с расписанием равномернее. Также необходимо актуализировать данные по количеству "отработанных" дней. Так как на набор рабочих используется
дважды, будем использовать временную таблицу.

Рабочий пример:

```
CREATE TEMPORARY TABLE `sh_users` (`id` INT(11) UNSIGNED NOT NULL);

INSERT INTO `sh_users`
SELECT users.id
FROM `users`
WHERE
(exclude_sat = 0 OR WEEKDAY('2015-04-18') <> 5) AND
(exclude_sun = 0 OR WEEKDAY('2015-04-18') <> 6) AND
id NOT IN (
  SELECT `user_id` FROM `schedule` WHERE `date` IN (
    SELECT MAX(`date`) AS `prev_date` FROM `schedule` WHERE `date` < '2015-04-18'
    UNION ALL
    SELECT MIN(`date`) AS `next_date` FROM `schedule` WHERE `date` > '2015-04-18'
  )
)
AND NOT EXISTS (SELECT * FROM `schedule` WHERE `date` = '2015-04-18')
ORDER BY users.num_work_days, RAND() LIMIT 4;

INSERT INTO `schedule` (`date`, `user_id`) SELECT '2015-04-18', `id` FROM `sh_users`;

UPDATE `users` SET `num_work_days` = `num_work_days` + 1 WHERE `id` IN (SELECT `id` FROM `sh_users`);

DROP TABLE `sh_users`;
```

Перед выполнением такого выражения необходимо убедиться, что записей на `2015-04-18` в таблице с расписанием нет. Это делается через условие в выражении:

```
AND NOT EXISTS (SELECT * FROM `schedule` WHERE `date` = '2015-04-18')
```

## Проверка

Наполнив расписание, проверим нормальность распределения (в примере - на 2000 дней):

```
SELECT schedule.user_id, COUNT(*) AS `count`, users.name
FROM `schedule`
JOIN `users` ON schedule.user_id = users.id
GROUP BY schedule.user_id ORDER BY `count` DESC;
```

Распределение нормальное.
Это получается потому, что, первыми в очереди идут рабочие с задолженностью "по отработке", а при одинаковом количестве - выбраются случайно.
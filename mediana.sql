-- Медиана - возможное значение признака, которое делит ранжированную совокупность 
-- на две равные части: 50 % «нижних» единиц ряда данных будут иметь значение признака не больше, чем медиана, 
-- а «верхние» 50 % — значения признака не меньше, чем медиана (wikipedia.org)

-- Вариант 1
-- Через подзапрос с LIMIT => подготовленное выражение
-- Высчитываем позицию первого значенения и количество значений (1 или 2) для выборки из ранжированного по возрастанию ряда
SELECT @med := (COUNT(*) + 1)/2 FROM `num`;
SELECT @lim:=IF(FLOOR(@med) = @med, 1, 2);
SELECT @offset := FLOOR(@med) - 1;
PREPARE stmt FROM 'SELECT AVG(`value`) FROM (SELECT `value` FROM `num` ORDER BY `value` LIMIT ?, ?) AS `alias`';
EXECUTE stmt USING @offset, @lim;
DEALLOCATE PREPARE stmt;


-- Вариант 2
-- Через таблицу, где значения в одном слолбце упорядочены по возрастанию, а в другом - по убыванию
-- Сравнив значения слева и справа, надо выбрать по одному значению (максимум и минимум) первого столбца по условию.
-- Условия два: alias_1.value <= alias_2.value и alias_1.value >= alias_2.value
-- По сути это математическое выражение слов 50% нижних единиц ряда имеют значение не больше, чем медиана,
-- а верхние 50 % - не меньше, чем медиана. Правая колонка служит для сравнения

-- Так выглядит эта таблица
SELECT @i1:=0, @i2:=0;
SELECT alias_1.i, alias_1.value, alias_2.i, alias_2.value FROM
  (SELECT @i1:=@i1+1 AS `i`, `value` FROM `num` ORDER BY `value` ASC) AS `alias_1`
JOIN 
  (SELECT @i2:=@i2+1 AS `i`, `value` FROM `num` ORDER BY `value` DESC) AS `alias_2`
ON alias_1.i = alias_2.i;

-- Определение медианы по ней

SELECT @i1:=0, @i2:=0;

SELECT AVG(`val`) FROM
  (SELECT MAX(alias_1.value) AS `val` FROM
    (SELECT @i1:=@i1+1 AS `i`, `value` FROM `num` ORDER BY `value` ASC) AS `alias_1`
  JOIN 
    (SELECT @i2:=@i2+1 AS `i`, `value` FROM `num` ORDER BY `value` DESC) AS `alias_2`
  ON alias_1.i = alias_2.i
    AND alias_1.value <= alias_2.value
    
  UNION
  
  SELECT MIN(alias_1.value) AS `val` FROM
    (SELECT @i1:=@i1+1 AS `i`, `value` FROM `num` ORDER BY `value` ASC) AS `alias_1`
  JOIN 
    (SELECT @i2:=@i2+1 AS `i`, `value` FROM `num` ORDER BY `value` DESC) AS `alias_2`
  ON alias_1.i = alias_2.i
    AND alias_1.value >= alias_2.value) AS `alias_3`;

-- Вариант 3
-- Определение по сумме. Вычисляем сумму значений
SELECT @sum:=SUM(`value`), @s:=0, @x1:=0, @x2:=0 FROM `num`;
-- Сумма первых упорядоченных по возрастанию значений должна быть меньше половины суммы значений, а при сложении с медианой - не меньше
SELECT `value`, @x1:=IF(`value` + @s >= @sum/2 AND @x1 = 0, `value`, @x1), @x2:=IF(@x1 = @sum/2, @x2, IF(@x1 = 0, `value`, @x2)), @s:=@s+`value`
FROM `num` ORDER BY `value`;
SELECT (@x1 + @x2) / 2 AS `mediana`;



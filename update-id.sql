-- Перенумерация строк
SET @t=0;
UPDATE `table` SET `field` = (@t := @t + 1);
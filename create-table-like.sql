-- Создание подобной таблицы

-- Полностью идентичной
CREATE TABLE `sectors` LIKE `news`;

-- Второй вариант
CREATE TABLE `sectors` AS SELECT * FROM `news` WHERE 1 = 0;

-- Только с указанными полями, в этом случае необходимо вручную добавить индексы, в том числе первичный ключ
CREATE TABLE `sectors` AS SELECT `id`, `idate`, `name` FROM `news` WHERE 1 = 0;
ALTER TABLE `sectors` ADD PRIMARY KEY(`id`), MODIFY `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT;

-- Наполнение полностью идентичной таблицы
INSERT INTO `sectors` SELECT * FROM `news`;
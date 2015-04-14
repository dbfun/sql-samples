# Умная сортировка

Сначала выводятся товары с заданным приоритетом `ord` от меньшего к большему (по возрастанию).

Однако товары с `ord` = 0 - в самом конце (ниже тех, у которых `ord` прописан).

При совпадении порядка сортировки `ord` сначала выводятся товары, которые есть в наличии (`in_stock = 1`),
затем те, у которых есть цена (`price <> 0`).

То есть вначале идут товары, которым прописали сортировку, причем имеющиеся в магазине и с указанной ценой,
в конце - товары без сортировки, отсутствующие в магазине и без цены. Удобно для витрины магазина.

## Модель данных

```
CREATE TABLE `shop_items`(
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `ord` INT(11) NOT NULL DEFAULT 0,
  `in_stock` TINYINT(1) NOT NULL DEFAULT 0,
  `price` DOUBLE NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

TRUNCATE `shop_items`;
INSERT INTO `shop_items` (`ord`, `in_stock`, `price`) VALUES
  (1, 1, 1000), -- первый, в магазине, с ценой
  (2, 1, 1500), -- второй, в магазине, с ценой
  (1, 1, 0), -- первый, в магазине, нет
  (1, 0, 800), -- первый, нет, с ценой
  (1, 0, 0), -- первый, нет, нет
  (3, 1, 1000), -- третий, в магазине, с ценой
  (4, 1, 1500), -- четвертый, в магазине, с ценой
  (5, 1, 0), -- пятый, в магазине, нет
  (-1, 1, 800), -- минус первый, нет, с ценой
  (7, 0, 0), -- седьмой, нет, нет
  (0, 1, 1800), -- без порядка, в магазине, с ценой
  (0, 1, 1300), -- без порядка, в магазине, с ценой
  (0, 0, 600), -- без порядка, нет, с ценой
  (0, 0, 900), -- без порядка, нет, с ценой
  (0, 0, 0); -- без порядка, нет, нет
```

## Решение 1. Простой способ

```
SELECT * FROM `shop_items` ORDER BY IF(`ord` <> 0, 0, 1), `ord`, `in_stock` DESC, IF(`price` <> 0, 0, 1);
```

## Решение 2. С помощью отдельного столбца `cool_ord`

```
ALTER TABLE `shop_items`
  ADD `cool_ord` INT(11) NOT NULL DEFAULT 0,
  ADD INDEX `idx_cool_ord` (`cool_ord`);
```

Обновление `cool_ord` - на триггерах и хранимой функции:

```
DELIMITER $$
  DROP FUNCTION IF EXISTS `COOL_ORD` $$
  DROP TRIGGER IF EXISTS `co_before_insert`$$
  DROP TRIGGER IF EXISTS `co_before_update`$$
  CREATE FUNCTION `COOL_ORD` (`ord` INT, in_stock INT, price DOUBLE) RETURNS INT DETERMINISTIC
  BEGIN
    DECLARE `cool_ord` INT(11);
    SET `cool_ord` = ord * 4;
    IF `cool_ord` = 0 THEN SET `cool_ord` = 10000;
    END IF;
    IF `in_stock` = 1 THEN SET `cool_ord` = `cool_ord` - 2;
    END IF;
    IF `price` <> 0 THEN SET `cool_ord` = `cool_ord` - 1;
    END IF;
    RETURN `cool_ord`;
    END $$

  CREATE TRIGGER `co_before_insert` BEFORE INSERT ON `shop_items`
  FOR EACH ROW BEGIN
    SET NEW.cool_ord = COOL_ORD(NEW.ord, NEW.in_stock, NEW.price);
  END;
  $$

  CREATE TRIGGER `co_before_update` BEFORE UPDATE ON `shop_items`
  FOR EACH ROW BEGIN
    SET NEW.cool_ord = COOL_ORD(NEW.ord, NEW.in_stock, NEW.price);
  END;
  $$
DELIMITER ;
```

Перерасчет новой сортировки:

```
UPDATE `shop_items` SET `cool_ord` = 0;
```

Сортировка по "умной сортировке":

```
SELECT * FROM `shop_items` ORDER BY `cool_ord`;
```
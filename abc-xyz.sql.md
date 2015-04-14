# ABC- и XYZ-анализ на SQL

## DB schema

```
CREATE TABLE IF NOT EXISTS `items` (
  `name` VARCHAR(255) DEFAULT NULL,
  `art` INT(11) NOT NULL,
  `count_sold` INT(11) DEFAULT NULL,
  `count_boxes` INT(11) DEFAULT NULL,
  PRIMARY KEY (`art`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
```

Table data:

```
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Степлер SAX 49',1238,455,325);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Степлер SAX 51',1245,410,1550);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Ручка Senator Spring',4589,398,530);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Ручка Pilot',4593,355,335);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Ручка Parker Sonet',4599,223,115);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Ручка Parker Insignia',4600,131,580);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Ручка Parker Frontier',4611,110,123);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Ручка Ico Omega',4678,95,525);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Тонер-картридж HP C7115X',5889,23,305);
INSERT INTO `items`(`name`,`art`,`count_sold`,`count_boxes`) values ('Тонер-картридж HPC8061A',5890,4,1800);
```

## ABC-, XYZ-analysis

```
START TRANSACTION;
SET @abc = 0;
SET @xyz = 0;
SELECT @cnt := COUNT(*) FROM `items`;
SET @pos_1 = ROUND(@cnt*0.2);
SET @pos_2 = @pos_1 + ROUND(@cnt*0.3);

SELECT abc_table.name, abc_table.art, abc_table.count_sold, abc_table.count_boxes,
abc_table.abc, xyz_table.xyz, CONCAT(abc_table.abc, xyz_table.xyz) AS `abc_xyz`,
CASE
    WHEN CONCAT(abc_table.abc, xyz_table.xyz) IN('AX', 'AY', 'BX') THEN 1
    WHEN CONCAT(abc_table.abc, xyz_table.xyz) IN('AZ', 'BY', 'CX') THEN 2
    ELSE 3
END AS `matrix_group`
FROM
(
  SELECT items.*, @abc:=@abc+1,
  CASE
      WHEN @abc <= @pos_1 THEN 'A'
      WHEN @abc <= @pos_2 THEN 'B'
      ELSE 'C'
  END AS `abc`
  FROM `items` ORDER BY `count_sold` DESC
) AS `abc_table`
JOIN
(
  SELECT items.art, @xyz:=@xyz+1,
  CASE
      WHEN @xyz <= @pos_1 THEN 'X'
      WHEN @xyz <= @pos_2 THEN 'Y'
      ELSE 'Z'
  END AS `xyz`
  FROM `items` ORDER BY `count_boxes` DESC
) AS `xyz_table`
USING(`art`)
ORDER BY `matrix_group`
;

COMMIT;
```
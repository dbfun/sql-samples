-- Функция транслитерации
DELIMITER $$

DROP FUNCTION IF EXISTS `transliterate` $$
CREATE FUNCTION `transliterate` (`str` TEXT) RETURNS TEXT CHARSET utf8 DETERMINISTIC
BEGIN
  DECLARE `str2` VARCHAR(2);
  DECLARE `str3` TEXT;
  DECLARE `len` INT(11);
  DECLARE `i` INT(11);
  SET `str3` = '';
  SET `i` = 1;
  SET `len` = CHAR_LENGTH(`str`); 
  -- идем циклом по символам строки
  WHILE `i` <= `len` DO -- выполняем преобразование припомощи функции ELT
    SET `str2` = ELT(
      INSTR(
        '1234567890абвгдеёжзийклмнопрстуфхцчшщыэюяabcdefghijklmnopqrstuvwxyz',
        SUBSTR(`str`, `i`, 1)
      ),
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
      'a', 'b', 'v', 'g', 'd', 'e', 'jo', 'zh', 'z', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r',
      's', 't', 'u', 'f', 'h', 'c', 'ch', 'sh', 'sh', 'y', 'e', 'yu','ya',
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    );
    IF `str2` IS NULL THEN -- если преобразование не прошло успешно добавляем в результат
      -- SET `str2` = SUBSTR(`str`,`i`,1); -- исходный символ
      SET `str2` = '-'; -- минус
    END IF;
    SET `str3` = CONCAT(`str3`, `str2`);
    SET `i` = `i` + 1;
  END WHILE;

  RETURN REPLACE(TRIM(BOTH '-' FROM `str3`), '--', '-');

END $$

DELIMITER ;
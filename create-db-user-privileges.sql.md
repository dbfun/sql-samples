# Создание типичной БД с полным доступом к ней пользователя по паролю

```
CREATE USER 'user'@'localhost' IDENTIFIED BY 'password';
CREATE DATABASE test_db;
GRANT ALL PRIVILEGES ON user.* TO 'test_db'@'localhost';
```
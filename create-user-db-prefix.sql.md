# Создание пользователя с привилегиями на базы с префиксом

Наделим пользователей

* `user@localhost` - доступом к базам с префиксом `run_`
* `user_test@localhost` - доступом к базам с префиксом `test_`

```sql
CREATE USER 'user'@'localhost' IDENTIFIED BY 'somePassword';
CREATE USER 'user_test'@'localhost' IDENTIFIED BY 'somePassword_test';
GRANT ALL PRIVILEGES ON  `run_%`.* TO 'user'@'localhost';
GRANT ALL PRIVILEGES ON  `test_%`.* TO 'user_test'@'localhost';
FLUSH PRIVILEGES;
```

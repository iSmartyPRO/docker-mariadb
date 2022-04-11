# Краткое описание
Сервер база данных MariaDB 10.6.7-focal.
Была выбрана именно эта база потому как она совместима с Zabbix, который я использую в своих ИТ инфраструктурах.

# Как установить
переименуйте .env.sample в .env и заполните своими данными

далее используйте следующую команду:
```
docker-compose up -d
```

# Примечание
Можно вручную удалить установку ADMINER отредактировав файл .env и docker-compose.yml

# Полезные команды

### Создание базы данных
```
CREATE DATABASE mydatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```
или
```
CREATE DATABASE mydatabase CHARACTER SET utf8mb4 COLLATE utf8_bin;
```

### MySQL: Создание пользователя в базе данных
```
CREATE USER 'username'@'%' IDENTIFIED BY 'some_password';
```

### MySQL: настройка доступа к базе данных для пользователя
```
GRANT ALL PRIVILEGES ON mydatabase.* TO 'username'@'%';
```

### MySQL: перезагрузка настроенных разрешений
```
FLUSH PRIVILEGES;
```

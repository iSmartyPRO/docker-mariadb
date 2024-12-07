#!/bin/bash

# Проверяем наличие .env файла
if [ ! -f .env ]; then
    echo "Файл .env не найден. Создайте его и укажите необходимые параметры."
    exit 1
fi

# Загружаем параметры из .env
export $(grep -v '^#' .env | xargs)

# Проверяем наличие необходимых переменных
if [ -z "$DOCKER_MARIADB_PORT" ] || [ -z "$DOCKER_CONTAINER_NAME" ] || [ -z "$MARIADB_ROOT_PASSWORD" ]; then
    echo "Некоторые параметры отсутствуют в .env файле. Убедитесь, что указаны DOCKER_MARIADB_PORT, DOCKER_CONTAINER_NAME и MARIADB_ROOT_PASSWORD."
    exit 1
fi

# Проверяем, запущен ли контейнер
if ! docker ps | grep -q "$DOCKER_CONTAINER_NAME"; then
    echo "Контейнер $DOCKER_CONTAINER_NAME не запущен. Запустите контейнер и повторите попытку."
    exit 1
fi

# Команда для отображения списка баз данных
SHOW_DB_COMMAND="SHOW DATABASES;"

echo "Получение списка баз данных из контейнера $DOCKER_CONTAINER_NAME..."

# Выполняем команду внутри контейнера
docker exec -i "$DOCKER_CONTAINER_NAME" mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "$SHOW_DB_COMMAND"

if [ $? -eq 0 ]; then
    echo "Список баз данных успешно отображён."
else
    echo "Произошла ошибка при получении списка баз данных."
fi
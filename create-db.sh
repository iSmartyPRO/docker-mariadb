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

# Функция для парсинга параметров
function parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --name) DB_NAME="$2"; shift ;;
            -h|--help)
                echo "Использование: $0 --name <имя_базы_данных>"
                exit 0
                ;;
            *) 
                echo "Неверный параметр: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# Парсим параметры
parse_args "$@"

# Проверяем, передано ли имя базы данных
if [ -z "$DB_NAME" ]; then
    echo "Ошибка: Не указано имя базы данных. Используйте --name <имя_базы_данных>."
    exit 1
fi

# Проверяем, запущен ли контейнер
if ! docker ps | grep -q "$DOCKER_CONTAINER_NAME"; then
    echo "Контейнер $DOCKER_CONTAINER_NAME не запущен. Запустите контейнер и повторите попытку."
    exit 1
fi

# Команда для создания базы данных
CREATE_DB_COMMAND="CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

echo "Попытка создать базу данных $DB_NAME в контейнере $DOCKER_CONTAINER_NAME..."

# Выполняем команду внутри контейнера
docker exec -i "$DOCKER_CONTAINER_NAME" mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "$CREATE_DB_COMMAND"

if [ $? -eq 0 ]; then
    echo "База данных $DB_NAME успешно создана."
else
    echo "Произошла ошибка при создании базы данных $DB_NAME."
fi

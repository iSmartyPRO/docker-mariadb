#!/bin/bash

# Проверяем наличие .env файла
if [ ! -f .env ]; then
    echo "Файл .env не найден. Создайте его и укажите необходимые параметры."
    exit 1
fi

# Загружаем параметры из .env
export $(grep -v '^#' .env | xargs)

# Проверяем наличие необходимых переменных
if [ -z "$DOCKER_CONTAINER_NAME" ] || [ -z "$MARIADB_ROOT_PASSWORD" ]; then
    echo "Некоторые параметры отсутствуют в .env файле. Убедитесь, что указаны DOCKER_CONTAINER_NAME и MARIADB_ROOT_PASSWORD."
    exit 1
fi

# Функция для парсинга аргументов
function parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --database) DATABASE="$2"; shift ;;
            -h|--help)
                echo "Использование: $0 --database <имя_базы_данных>"
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
if [ -z "$DATABASE" ]; then
    echo "Ошибка: Не указано имя базы данных. Используйте --database <имя_базы_данных>."
    exit 1
fi

# Проверяем, запущен ли контейнер
if ! docker ps | grep -q "$DOCKER_CONTAINER_NAME"; then
    echo "Контейнер $DOCKER_CONTAINER_NAME не запущен. Запустите контейнер и повторите попытку."
    exit 1
fi

# Команда для отображения таблиц
SHOW_TABLES_COMMAND="SHOW TABLES FROM \`$DATABASE\`;"

echo "Получение списка таблиц из базы данных $DATABASE..."

# Выполняем команду внутри контейнера
docker exec -i "$DOCKER_CONTAINER_NAME" mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "$SHOW_TABLES_COMMAND"
if [ $? -ne 0 ]; then
    echo "Ошибка при получении списка таблиц из базы данных $DATABASE."
    exit 1
fi

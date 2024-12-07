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
            --user) USERNAME="$2"; shift ;;
            --password) PASSWORD="$2"; shift ;;
            --database) DATABASE="$2"; shift ;;
            -h|--help)
                echo "Использование: $0 --user <имя_пользователя> --password <пароль> [--database <имя_базы_данных>]"
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

# Проверяем, переданы ли обязательные параметры
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Ошибка: Не указаны имя пользователя или пароль. Используйте --user <имя_пользователя> --password <пароль>."
    exit 1
fi

# Проверяем, запущен ли контейнер
if ! docker ps | grep -q "$DOCKER_CONTAINER_NAME"; then
    echo "Контейнер $DOCKER_CONTAINER_NAME не запущен. Запустите контейнер и повторите попытку."
    exit 1
fi

# Команда для создания пользователя
CREATE_USER_COMMAND="CREATE USER IF NOT EXISTS '$USERNAME'@'%' IDENTIFIED BY '$PASSWORD';"

# Команда для назначения прав (если указана база данных)
if [ -n "$DATABASE" ]; then
    GRANT_PRIVILEGES_COMMAND="GRANT ALL PRIVILEGES ON \`$DATABASE\`.* TO '$USERNAME'@'%'; FLUSH PRIVILEGES;"
else
    GRANT_PRIVILEGES_COMMAND="FLUSH PRIVILEGES;"
fi

echo "Создание пользователя $USERNAME..."

# Выполняем команды внутри контейнера
docker exec -i "$DOCKER_CONTAINER_NAME" mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "$CREATE_USER_COMMAND"
if [ $? -ne 0 ]; then
    echo "Ошибка при создании пользователя $USERNAME."
    exit 1
fi

if [ -n "$DATABASE" ]; then
    echo "Назначение прав на базу данных $DATABASE пользователю $USERNAME..."
    docker exec -i "$DOCKER_CONTAINER_NAME" mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "$GRANT_PRIVILEGES_COMMAND"
    if [ $? -ne 0 ]; then
        echo "Ошибка при назначении прав для базы данных $DATABASE пользователю $USERNAME."
        exit 1
    fi
fi

echo "Пользователь $USERNAME успешно создан."
if [ -n "$DATABASE" ]; then
    echo "Полные права на базу данных $DATABASE назначены пользователю $USERNAME."
fi

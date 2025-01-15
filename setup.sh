#!/bin/bash

# Скрипт для настройки SSH-доступа и создания пользователя

# Проверка запуска от root
echo "Проверка запуска от root"
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт от имени root."
  exit 1
fi

apt update
apt upgrade

# Переменные пользователя
USERNAME="aboldyrev"

# Запрос пароля или автоматическая генерация
echo "Запрос пароля или автоматическая генерация"
read -p "Введите пароль для пользователя $USERNAME (оставьте пустым для автоматической генерации): " PASSWORD
if [ -z "$PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 12 | tr -d '\n')  # Убираем возможные символы новой строки
  # echo "Сгенерированный пароль для $USERNAME: $PASSWORD"
fi

# Создание пользователя
echo "Создание пользователя"
if id "$USERNAME" &>/dev/null; then
  echo "Пользователь $USERNAME уже существует."
else
  useradd -m -s /bin/bash $USERNAME
  echo -e "$PASSWORD\n$PASSWORD" | passwd "$USERNAME"
  echo "Пользователь $USERNAME создан."
fi

# Добавление в группу sudo
echo "Добавление в группу sudo"
usermod -aG sudo $USERNAME

# Отключение SSH-доступа для root
echo "Отключение SSH-доступа для root"
SSHD_CONFIG="/etc/ssh/sshd_config"
if grep -q "^PermitRootLogin" $SSHD_CONFIG; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSHD_CONFIG
else
  echo "PermitRootLogin no" >> $SSHD_CONFIG
fi

# Перезагрузка службы SSH
systemctl restart sshd

# Вывод информации
cat << EOF
Настройка завершена:
- Пользователь $USERNAME создан.
- Пароль: $PASSWORD
- Пользователь добавлен в группу sudo.
- Доступ root по SSH отключён.
EOF

exit 0

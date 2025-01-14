#!/bin/bash

# Скрипт для настройки SSH-доступа и создания пользователя

# Проверка запуска от root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт от имени root."
  exit 1
fi

# Переменные пользователя
USERNAME="aboldyrev"

# Запрос пароля или автоматическая генерация
read -p "Введите пароль для пользователя $USERNAME (оставьте пустым для автоматической генерации): " PASSWORD
if [ -z "$PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 12)
fi

# Создание пользователя
if id "$USERNAME" &>/dev/null; then
  echo "Пользователь $USERNAME уже существует."
else
  useradd -m -s /bin/bash $USERNAME
  echo "$USERNAME:$PASSWORD" | chpasswd
  echo "Пользователь $USERNAME создан."
fi

# Добавление в группу sudo
usermod -aG sudo $USERNAME

# Отключение SSH-доступа для root
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

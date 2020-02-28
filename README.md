# Запуск
**С помощью клонирования репозитория**
```
apt-get install -y git
git clone https://github.com/OwnWayST/enginegp-ai
cd egpv3-ai
bash egpv3.sh
```
# Частые ошибки
**Недействительные/Плохие репозитории**
Решается сменой репозиториев. Пример файла /etc/apt/sources.list.
````
deb http://mirror.yandex.ru/debian buster main contrib
deb-src http://mirror.yandex.ru/debian buster main contrib

deb http://security.debian.org/debian-security buster/updates main contrib
deb-src http://security.debian.org/debian-security buster/updates main contrib
````

# Credits
    vk.com/enginegamespanel - за файловый сервер и некоторые функции с их автоустановщика.

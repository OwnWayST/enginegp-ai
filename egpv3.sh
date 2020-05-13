#!/bin/bash
CODENAME=$(awk -F= '$1=="VERSION_CODENAME" { print $2 ;}' /etc/os-release)
IPADDR=$(echo "${SSH_CONNECTION}" | awk '{print $3}')
MIRROR="https://mirror.enginegp.ru"
GAMES="http://games.enginegp.ru"
COUNTER=1
MAX_STEPS_CP=8
MAX_STEPS_CS=6
DIR="/var/enginegp"

PMA_PASS=""
PMA_LOGIN=""

FTPPASS=""
MYSQLPASS=""
ENGINEGPPASS=""
ENGINEGPHASH=""
CRONKEY=""
CRONPANEL="/etc/crontab"

# Элементы дизайна
Infon() {
	printf "\033[1;32m$@\033[0m"
}
Info()
{
	Infon "$@\n"
}
Error()
{
	printf "\033[1;31m$@\033[0m\n"
}
Error_n()
{
	Error "$@"
}
Error_s()
{
	Error "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
}
log_s()
{
	Info "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
}
log_n()
{
	Info "$@"
}
log_t()
{
	log_s
	Info "- - - $@"
 	log_s
}

copy() {
	log_t "EGPv3 AutoInstaller by vk.com/ownwayst"
	Info "	Помощь по панели vk.com/enginegamespanel"
	echo ""
	Info "Credits:	"
	Info "  	vk.com/enginegamespanel - файловые сервера и некоторые функции установки"
	echo ""
	echo ""
}

mainMenu() {
	Info "	1) Установить Панель Управления"
	Info " 	2) Настроить Локацию"
	Info " 	3) Скачать игры"
	Info "	4) Установить PMA (PhpMyAdmin)"
	Info "  5) Установить MCE (MySQL Config Editor)"

	read -p "Выберите нужное действие: " case 

	case $case in 
		0) exit;;
		1) cpInstall;;
		2) vsConf;;
		3) gamesMenu;;
		4) pmaInstall;;
		5) mceInstall;;
	esac
} 

mceInstall() {
	resetVariables
	clear
	copy
	askMySQL
	echo ""
	echo ""	
	log_t "Установка MCE"
	mysql_config_editor set --login-path=local --host=localhost --user=root --password=$MYSQLPASS
}

pmaInstall() {
	resetVariables
	clear
	copy
	askDomain
	askMySQL
	echo ""
	echo ""	
	log_t "Установка PhpMyAdmin"
	installPma
	endInstallPMA
}

installPma() {
	PHPV=$(php5.6 -v)

	if [[ "$PHPV" = "" ]]; then
		Error "[ERRROR] На Машине не найден php5.6"
		exit
	fi	

	cd ~
	wget https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-english.tar.gz
	tar xvf phpMyAdmin-4.9.4-english.tar.gz
	sudo mv phpMyAdmin-4.9.4-english/ /usr/share/phpmyadmin
	mkdir -p /var/lib/phpmyadmin/tmp
	chown -R www-data:www-data /var/lib/phpmyadmin
	cp /root/egpv3-ai/config.inc.php /usr/share/phpmyadmin/config.inc.php

	PMA_PASS=$(pwgen -cns -1 12)
	PMA_LOGIN="pma"

	BLOWFISH=$(pwgen -cns -1 32)

	cd /usr/share/phpmyadmin

	sed -i "s/_BLOWFISH_/${BLOWFISH}/g" config.inc.php
	sed -i "s/_pma_/${PMA_LOGIN}/g" config.inc.php
	sed -i "s/_pmapass_/${PMA_PASS}/g" config.inc.php

	mysql -uroot -p$MYSQLPASS < /usr/share/phpmyadmin/sql/create_tables.sql
	mysql -uroot -p$MYSQLPASS -e "CREATE USER '$PMA_LOGIN'@'localhost' IDENTIFIED BY '$PMA_PASS';";
	mysql -uroot -p$MYSQLPASS -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO '$PMA_LOGIN'@'localhost' IDENTIFIED BY '$PMA_PASS';";

	FILE='/etc/apache2/conf-available/phpmyadmin.conf'

	echo "Alias /phpmyadmin /usr/share/phpmyadmin" > $FILE
	echo "<Directory /usr/share/phpmyadmin>" >> $FILE
	echo "	Options SymLinksIfOwnerMatch" >> $FILE
	echo "	DirectoryIndex index.php" >> $FILE
	echo "	<IfModule mod_php5.c>" >> $FILE
	echo "	<IfModule mod_mime.c>" >> $FILE
	echo "		AddType application/x-httpd-php .php" >> $FILE
	echo "	</IfModule>" >> $FILE
	echo "	<FilesMatch \".+\.php$\">" >> $FILE
	echo "		SetHandler application/x-httpd-php" >> $FILE
	echo "	</FilesMatch>" >> $FILE
	echo "	php_value include_path ." >> $FILE
	echo "	php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp" >> $FILE
	echo "	php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/" >> $FILE
	echo "	php_admin_value mbstring.func_overload 0" >> $FILE
	echo "	</IfModule>" >> $FILE
	echo "	<IfModule mod_php.c>" >> $FILE
	echo "	<IfModule mod_mime.c>" >> $FILE
	echo "		AddType application/x-httpd-php .php" >> $FILE
	echo "	</IfModule>" >> $FILE
	echo "	<FilesMatch \".+\.php$\">" >> $FILE
	echo "		SetHandler application/x-httpd-php" >> $FILE
	echo "	</FilesMatch>" >> $FILE
	echo "	php_value include_path ." >> $FILE
	echo "	php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp" >> $FILE
	echo "	php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/" >> $FILE
	echo "	php_admin_value mbstring.func_overload 0" >> $FILE
	echo "	</IfModule>" >> $FILE
	echo "	</Directory>" >> $FILE
	echo "	<Directory /usr/share/phpmyadmin/setup>" >> $FILE
	echo "	<IfModule mod_authz_core.c>" >> $FILE
	echo "	<IfModule mod_authn_file.c>" >> $FILE
	echo "	AuthType Basic" >> $FILE
	echo "	AuthName \"phpMyAdmin Setup\"" >> $FILE
	echo "	AuthUserFile /etc/phpmyadmin/htpasswd.setup" >> $FILE
	echo "	</IfModule>" >> $FILE
	echo "	Require valid-user" >> $FILE
	echo "	</IfModule>" >> $FILE
	echo "	</Directory>" >> $FILE
	echo "	<Directory /usr/share/phpmyadmin/templates>" >> $FILE
	echo "		Require all denied" >> $FILE
	echo "	</Directory>" >> $FILE
	echo "	<Directory /usr/share/phpmyadmin/libraries>" >> $FILE
	echo "		Require all denied" >> $FILE
	echo "	</Directory>" >> $FILE
	echo "	<Directory /usr/share/phpmyadmin/setup/lib>" >> $FILE
	echo "		Require all denied" >> $FILE
	echo "	</Directory>" >> $FILE

	sudo a2enconf phpmyadmin.conf
	sudo systemctl reload apache2
}

endInstallPMA() {
	log_t " 	Настройка PMA завершена 	"
	Info "[MySQL]: "
	Info "	Точка входа: $IPADDR/phpmyadmin"
	Info "	Логин: $PMA_LOGIN"
	Info "	Пароль: $PMA_PASS"	
	echo ""
	Info "[!] Сохраните данные к себе в отдельный файл [!]"
}

gamesList=("CS 1.6 (ReHLDS)" "CS:S v34" "CS:S" "CS:GO" "SA:MP (0.3.7-R2)" "CR:MP" "MTA" "Minecraft (1.12)")

gamesDownloadType=(0 0 232330 740 0 0 0 0)	

gamesSystemName=("cs" "cssold" "css" "csglobal" "samp" "crmp" "mta" "mc")

gamesSubPath=("rehlds" "cssv34" "" "" "037_R2" "037_C5" "155_R2" "CB112_R01")

gamesMenu() {
	clear 
	copy

	for (( i = 0; i < ${#gamesList[@]}; i++ )); do
		Info "	${i}) ${gamesList[i]}"
	done

	read -p "Укажите номер игры: " gameId

	if [ "$gameId" -ge "0" ] && [ "$gameId" -le "${#gamesList[@]}" ]; then
		gameInstall "${gameId}"
	else
		Error "[ERROR] Неопределенный ID игры ${gameId}"
		exit
	fi
}

gameInstall() {
	if [ -z "$1" ]; then
		Error "[ERROR] Пустой аргумент [Func: gameInstall]"
		exit
	fi

	mkdir /path/${gamesSystemName["$1"]}/${gamesSubPath["$1"]} -p
	cd /path/${gamesSystemName["$1"]}/${gamesSubPath["$1"]}
	if [[ ${gamesDownloadType["$1"]} > 0 ]]; then
	   cd /path/cmd/
	   ./steamcmd.sh +login anonymous +force_install_dir /path/${gamesSubPath["$1"]}/ +app_update ${gamesDownloadType["$1"]} validate +quit
	else 
		wget --no-check-certificate "$GAMES/${gamesSystemName["$1"]}/${gamesSubPath["$1"]}.zip"
		unzip ${gamesSubPath["$1"]}.zip
		rm ${gamesSubPath["$1"]}.zip
	fi
}

vsConf() {
	resetVariables
	clear 
	copy 
	echo ""
	echo ""
	log_t "Обновление системы [${COUNTER}/${MAX_STEPS_CS}]"
	systemUpdate
	log_t "Установка необходимых пакетов [${COUNTER}/${MAX_STEPS_CS}]"
	npInstall "location"	
	askMySQL
	log_t "Установка MySQL v5.7 [${COUNTER}/${MAX_STEPS_CS}]"
	log_t "Установка ProFTPD [${COUNTER}/${MAX_STEPS_CS}]"
	proftpdInstall
	log_t "Установка Nginx [${COUNTER}/${MAX_STEPS_CS}]"
	nginxInstall; nginxConfigure
	log_t "Настройка локации [${COUNTER}/${MAX_STEPS_CS}]"
	cLocation
	endConfiguringLocation
}

nginxInstall() {
	apt-get install -y nginx >> /dev/null
	((COUNTER += 1))
}

nginxConfigure() {
	mv nginx /etc/nginx/nginx.conf
}

proftpdInstall() {
	apt-get install -y proftpd-basic proftpd-mod-mysql >> /dev/null
 
	FTPPASS=$(pwgen -cns -1 12)

	mv proftpd /etc/proftpd/proftpd.conf
	mv proftpd_modules /etc/proftpd/modules.conf
	mv proftpd_sql /etc/proftpd/sql.conf

	mysql -u root -p$MYSQLPASS -e "CREATE DATABASE ftp;";
	mysql -u root -p$MYSQLPASS -e "CREATE USER 'ftp'@'localhost' IDENTIFIED BY '$FTPPASS';";
	mysql -u root -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON ftp . * TO 'ftp'@'localhost';";
	mysql -u root -p$MYSQLPASS ftp < sqldump.sql;

	rm -rf sqldump.sql
	sed -i 's/passwdfor/'$MYSQLPASS'/g' /etc/proftpd/sql.conf

	((COUNTER += 1))
}

cLocation() {
	sudo apt-get install -y lib32gcc1 gdb-minimal ntpdate lsof default-jre qstat mc gdb >> /dev/null
	dpkg --add-architecture i386
	sudo apt-get install -y gcc-multilib >> /dev/null
	dpkg-reconfigure tzdata -f noninteractive

	cat rclocal >> /etc/rc.local

 	touch /root/iptables_block
 	chmod 500 /root/iptables_block

	mkdir -p /path /path/cmd /path/maps /servers
	mkdir -p /path/cs /path/samp /path/crmp /path/mta /path/mc
	mkdir -p /path/maps/cs /path/maps/cssold /path/maps/css /path/maps/csgo
	chmod -R 711 /servers
	chmod -R 755 /path
	chown root:servers /servers /path
	groupmod -g 998 `cat /etc/group | grep :1000 | awk -F":" '{print $1}'`
	groupadd -g 1000 servers;
	cd /path/cmd/
	wget http://media.steampowered.com/client/steamcmd_linux.tar.gz
	tar xvzf steamcmd_linux.tar.gz
	rm steamcmd_linux.tar.gz

	mkdir -p /copy /servers /path/cmd /path/maps /var/nginx
 	cd /path/cmd && wget http://media.steampowered.com/client/steamcmd_linux.tar.gz && tar xvfz steamcmd_linux.tar.gz && rm steamcmd_linux.tar.gz
 	groupmod -g 998 `cat /etc/group | grep :1000 | awk -F":" '{print $1}'`
 	groupadd -g 1000 servers;
 	chmod 711 /servers; chown root:servers /servers
 	chmod -R 755 /path; chown path:servers /path
 	chmod -R 750 /copy; chown root:root /copy
 	chmod -R 750 /etc/proftpd

	systemctl restart -n0 proftpd
	systemctl enable -n0 proftpd
	systemctl restart -n0 nginx
	systemctl enable -n0 nginx

	((COUNTER += 1))
}

cpInstall() {
	resetVariables
	clear
	copy
	askDomain
	echo ""
	echo ""
	log_t "Обновление системы [${COUNTER}/${MAX_STEPS_CP}]"
	systemUpdate
	log_t "Установка необходимых пакетов [${COUNTER}/${MAX_STEPS_CP}]"
	npInstall
	log_t "Установка Apache2 [${COUNTER}/${MAX_STEPS_CP}]"
	a2Install
	log_t "Установка PHP 5.6 [${COUNTER}/${MAX_STEPS_CP}]"
	p7Install
	log_t "Установка Memcached [${COUNTER}/${MAX_STEPS_CP}]"
	mcInstall
	log_t "Установка MySQL v5.7 [${COUNTER}/${MAX_STEPS_CP}]"
	dbInstall
	log_t "Настройка crontab [${COUNTER}/${MAX_STEPS_CP}]"
	ctConfiguring
	log_t "Установка EGPv3 [${COUNTER}/${MAX_STEPS_CP}]"
	diPanel			
	endInstallCP			
}

askDomain() {
	echo ""
	Info "Если нет подключенного домена, оставьте поле пустым"
	read -p "Домен: " domainName

	if [[ "$domainName" != "" ]]; then
		IPADDR="$domainName"
	fi
}

askMySQL() {
	echo ""
	Info "Если на машине не установлен MySQL, оставьте поле пустым"
	read -p "Пароль от root MySQL: " dbPass

	if [[ "$dbPass" != "" ]]; then
		MYSQLPASS="$dbPass"
	else
		dbInstall
	fi
}

endInstallCP() {
	log_t " 	Установка панели завершена 	"
	Info "[Панель Управления]: "
	Info "	Точка входа: http://$IPADDR/"
	Info "	Логин: 	root"
	Info "	Пароль: $ENGINEGPPASS"
	echo ""
	Info "[MySQL]: "
	Info "	Логин: root"
	Info "	Пароль: $MYSQLPASS"
	echo ""
	Info "[!] Сохраните данные к себе в отдельный файл [!]"
}

endConfiguringLocation() {
	log_t " 	Настройка локации завершена 	"
	Info "[MySQL]: "
	Info "	Логин: root"
	Info "	Пароль: $MYSQLPASS"	
	echo ""
	Info "	Логин: ftp"
	Info "	Пароль: $FTPPASS"
	Info "[!] Сохраните данные к себе в отдельный файл [!]"
}

systemUpdate() {
	apt-get install -y sudo >> /dev/null

	# todo: fix gui select MySQL version
	sudo apt-get update -y 
	sudo apt-get upgrade -y 	

	((COUNTER += 1))
}

npInstall() {
	sudo apt-get install -y apt-utils pwgen wget dialog curl gnupg2 ca-certificates lsb-release apt-transport-https cron unzip sudo nano zip ssh tcpdump htop screen >> /dev/null
	
	if [[ "$1" != "" ]]; then
	 	mkdir -p /temp; cd /temp/
		wget --no-check-certificate -O proftpd $MIRROR/files/proftpd/proftpd
		wget --no-check-certificate -O proftpd_modules $MIRROR/files/proftpd/proftpd_modules
		wget --no-check-certificate -O proftpd_sql $MIRROR/files/proftpd/proftpd_sql
		wget --no-check-certificate $MIRROR/files/proftpd/sqldump.sql
		wget --no-check-certificate -O rclocal $MIRROR/files/rclocal/rclocal
		wget --no-check-certificate -O nginx $MIRROR/files/nginx/nginx
	fi

	((COUNTER += 1))
}

a2Install() {
	sudo apt-get install -y apache2 >> /dev/null

	APACHEV=$(apache2 -v)

	if [[ "$APACHEV" = "" ]]; then
		Error "[ERRROR] Ошибка установки Apache2"
		exit
	fi

	mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/.000-default.conf

	FILE='/etc/apache2/sites-available/000-default.conf'

	echo "<VirtualHost *:80>" > $FILE
	echo "	ServerName $IPADDR" >> $FILE
	echo "	DocumentRoot $DIR" >> $FILE
	echo "	<Directory $DIR/>" >> $FILE
	echo "		Options Indexes FollowSymLinks MultiViews" >> $FILE
	echo "		AllowOverride All" >> $FILE
	echo "		Require all granted" >> $FILE
	echo "	</Directory>" >> $FILE
	echo "	ErrorLog \${APACHE_LOG_DIR}/error.log" >> $FILE
	echo "	LogLevel warn" >> $FILE
	echo "	CustomLog \${APACHE_LOG_DIR}/access.log combined" >> $FILE
	echo "</VirtualHost>" >> $FILE

	a2enmod rewrite >> /dev/null

	systemctl restart -n0 apache2 
	systemctl enable -n0 apache2 

	((COUNTER += 1))
}

p7Install() {
	wget -q https://packages.sury.org/php/apt.gpg 
	sudo apt-key add apt.gpg  > /dev/null 2>&1
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php7.list
	sudo apt-get install -y php5.6 php5.6-cli php5.6-common php5.6-json php5.6-memcache php5.6-mysql php5.6-curl php5.6-dev php5.6-ssh2 php5.6-gd php5.6-mbstring libapache2-mod-php5.6 php-pear >> /dev/null

	PHPV=$(php5.6 -v)

	if [[ "$PHPV" = "" ]]; then
		Error "[ERRROR] Ошибка установки PHP 7.3"
		exit
	fi	

	a2enmod php5.6 >> /dev/null
	service apache2 restart >> /dev/null

	((COUNTER += 1))
}

mcInstall() {
	sudo apt-get install -y memcached >> /dev/null

	MCV=$(memcached -V)

	if [[ "$MCV" = "" ]]; then
		Error "[ERRROR] Ошибка установки Memcached"
		exit
	fi	

	echo "-U 0" >> /etc/memcached.conf
	systemctl restart -n0 memcached 
	systemctl enable -n0 memcached 

	((COUNTER += 1))
}

dbInstall() {
	MYSQLPASS=$(pwgen -cns -1 12)

	wget -q --no-check-certificate https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
	export DEBIAN_FRONTEND=noninteractive
	echo mysql-apt-config mysql-apt-config/select-server select mysql-5.7 | debconf-set-selections
	echo mysql-apt-config mysql-apt-config/select-product select Ok | debconf-set-selections
	dpkg -i mysql-apt-config_0.8.13-1_all.deb >> /dev/null
	sudo apt-get update >> /dev/null
	echo mysql-community-server mysql-community-server/root-pass password "$MYSQLPASS" | debconf-set-selections
	echo mysql-community-server mysql-community-server/re-root-pass password "$MYSQLPASS" | debconf-set-selections
	sudo apt-get install -y mysql-server >> /dev/null
	rm mysql-apt-config_0.8.13-1_all.deb

	((COUNTER += 1))
}

ctConfiguring() {
	CRONKEY=$(pwgen -cns -1 6)

	echo "*/2 * * * * screen -dmS scan_servers bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers'" >> $CRONPANEL
	echo "*/5 * * * * screen -dmS scan_servers_load bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_load'" >> $CRONPANEL
	echo "*/5 * * * * screen -dmS scan_servers_route bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_route'" >> $CRONPANEL
	echo "* * * * * screen -dmS scan_servers_down bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_down'" >> $CRONPANEL
	echo "*/10 * * * * screen -dmS notice_help bash -c 'cd ${DIR} && php cron.php ${CRONKEY} notice_help'" >> $CRONPANEL
	echo "*/15 * * * * screen -dmS scan_servers_stop bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_stop'" >> $CRONPANEL
	echo "*/15 * * * * screen -dmS scan_servers_copy bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_copy'" >> $CRONPANEL
	echo "*/30 * * * * screen -dmS notice_server_overdue bash -c 'cd ${DIR} && php cron.php ${CRONKEY} notice_server_overdue'" >> $CRONPANEL
	echo "*/30 * * * * screen -dmS preparing_web_delete bash -c 'cd ${DIR} && php cron.php ${CRONKEY} preparing_web_delete'" >> $CRONPANEL
	echo "0 * * * * screen -dmS scan_servers_admins bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_admins'" >> $CRONPANEL
	echo "* * * * * screen -dmS control_delete bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_delete'" >> $CRONPANEL
	echo "* * * * * screen -dmS control_install bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_install'" >> $CRONPANEL
	echo "*/2 * * * * screen -dmS scan_control bash -c 'cd ${DIR} && php cron.php ${CRONKEY} scan_control'" >> $CRONPANEL
	echo "*/2 * * * * screen -dmS control_scan_servers bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers'" >> $CRONPANEL
	echo "*/5 * * * * screen -dmS control_scan_servers_route bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_route'" >> $CRONPANEL
	echo "* * * * * screen -dmS control_scan_servers_down bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_down'" >> $CRONPANEL
	echo "0 * * * * screen -dmS control_scan_servers_admins bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_admins'" >> $CRONPANEL
	echo "*/15 * * * * screen -dmS control_scan_servers_copy bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_copy'" >> $CRONPANEL
	echo "0 0 * * * screen -dmS graph_servers_day bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads graph_servers_day'" >> $CRONPANEL
	echo "0 * * * * screen -dmS graph_servers_hour bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads graph_servers_hour'" >> $CRONPANEL
	echo "#">>$CRONPANEL
 	crontab -u root /etc/crontab
 	chown root:crontab /var/spool/cron/crontabs/root
 	service cron restart

 	((COUNTER += 1))
}

diPanel() {
	ENGINEGPPASS=$(pwgen -cns -1 12)
	ENGINEGPHASH=$(echo -n "$ENGINEGPPASS" | md5sum | cut -d " " -f1)

	cd ~

	wget -q --no-check-certificate $MIRROR/panel/enginegp.sql 
 	wget -q --no-check-certificate $MIRROR/panel/enginegp.zip 
 	mkdir $DIR/
 	cd
	mkdir /var/lib/mysql/enginegp
	chown -R mysql:mysql /var/lib/mysql/enginegp
	cd
	sed -i "s/IPADDR/${IPADDR}/g" /root/enginegp.sql
	sed -i "s/ENGINEGPHASH/${ENGINEGPHASH}/g" /root/enginegp.sql
	mysql -u root -p$MYSQLPASS enginegp < enginegp.sql
	rm enginegp.sql
	unzip /root/enginegp.zip -d $DIR/ >> /dev/null
	sed -i "s/MYSQLPASS/${MYSQLPASS}/g" $DIR/system/data/mysql.php
	sed -i "s/IPADDR/${IPADDR}/g" $DIR/system/data/config.php
	sed -i "s/CRONKEY/${CRONKEY}/g" $DIR/system/data/config.php
	rm enginegp.zip
	chown -R www-data:www-data $DIR/
	chmod -R 775 $DIR/
	echo "Europe/Moscow" > /etc/timezone
	dpkg-reconfigure tzdata -f noninteractive
	sudo sed -i -r 's~^;date\.timezone =$~date.timezone = "Europe/Moscow"~' /etc/php/7.3/cli/php.ini
	sudo sed -i -r 's~^;date\.timezone =$~date.timezone = "Europe/Moscow"~' /etc/php/7.3/apache2/php.ini

	((COUNTER += 1))
}

resetVariables() {		
	FTPPASS=""
	MYSQLPASS=""
	ENGINEGPPASS=""
	ENGINEGPHASH=""
	CRONKEY=""	
	COUNTER=1
	IPADDR=$(echo "${SSH_CONNECTION}" | awk '{print $3}')
}

copy

if [ $CODENAME = "buster" ] || [ $CODENAME = "stretch" ]; then
	mainMenu
else
	Error "[ERRROR] Неопределенный дистрибутив ${CODENAME}. Минимальная версия OS: Debian 9/10"
fi

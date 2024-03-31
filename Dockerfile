FROM ubuntu:23.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update
RUN apt-get install -y --no-install-recommends openjdk-17-jre
RUN apt-get install -y mysql-server
RUN apt-get install -y nginx
RUN apt-get install -y php-fpm php-mysql

COPY mysql/my.cnf /etc/mysql/conf.d/my.cnf
COPY mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

# https://stackoverflow.com/questions/62987154/mysql-wont-start-error-su-warning-cannot-change-directory-to-nonexistent
RUN service mysql stop
RUN usermod -d /var/lib/mysql/ mysql
RUN service mysql start

# 设置root密码
# RUN service mysql start && mysql -e "CREATE USER 'root2'@'%' IDENTIFIED BY '111111';GRANT ALL PRIVILEGES ON *.* TO 'root2'@'%';FLUSH PRIVILEGES;"
RUN service mysql start && mysql -e "CREATE DATABASE IF NOT EXISTS moneynote CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
RUN service mysql start && mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '78p7gkc1'; use mysql;update user set host='%' where user='root';FLUSH PRIVILEGES;"

COPY ./api/*.jar /app/app.jar

COPY ./nginx/default /etc/nginx/sites-available/default
COPY ./phpmyadmin/ /var/www/html
RUN chown -R www-data:www-data /var/www/html

COPY ./nginx/pc.conf /etc/nginx/sites-available/pc.conf
COPY ./pc/ /var/www/pc
RUN ln -s /etc/nginx/sites-available/pc.conf /etc/nginx/sites-enabled/
RUN chown -R www-data:www-data /var/www/pc

COPY ./nginx/h5.conf /etc/nginx/sites-available/h5.conf
COPY ./h5/ /var/www/h5
RUN ln -s /etc/nginx/sites-available/h5.conf /etc/nginx/sites-enabled/
RUN chown -R www-data:www-data /var/www/h5

WORKDIR /app
# CMD service php8.1-fpm start && service mysql start && nginx -g 'daemon off;'
CMD service php8.1-fpm start && service mysql start && service nginx start && java -jar app.jar
#CMD ["sh", "-c", "service php8.1-fpm start && service mysql start && service nginx start && java -jar app.jar"]

EXPOSE 3306
EXPOSE 80
EXPOSE 9092
EXPOSE 81
EXPOSE 82
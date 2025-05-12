docker exec -it monarc_apache apt install python3-pymysql -y
docker exec -it monarc_apache apt install python3-tqdm -y
docker exec -it monarc_apache python3 /usr/src/app/3-translate-db.py
docker cp ./helper/pt/. monarc_apache:/var/lib/monarc/fo/deliveries/cases/EN/
docker exec -it monarc_apache chown -R www-data:www-data /var/lib/monarc/fo/deliveries/cases/EN
docker exec -it monarc_apache  chmod -R 755 /var/lib/monarc/fo/deliveries/cases/EN

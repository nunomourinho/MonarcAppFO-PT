 docker exec -it monarc_apache apt install python3-pymysql -y
 docker exec -it monarc_apache apt install python3-tqdm -y
 docker exec -it monarc_apache python3 /usr/src/app/3-translate-db.py

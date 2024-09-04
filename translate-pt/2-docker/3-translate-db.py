import csv
import os
import pymysql
from tqdm import tqdm

# Load environment variables from env.txt
env_path = '/docker-entrypoint-initdb.d/.env'
with open(env_path) as f:
    for line in f:
        if not line.startswith('#'):
            var = line.strip().split('=')
            if len(var) == 2:
                os.environ[var[0]] = var[1]

# Database connection details from environment variables
db_host = 'mariadb'
db_user = os.getenv('MYSQL_USER')
db_password = os.getenv('MYSQL_PASSWORD')
db_name = os.getenv('MYSQL_DATABASE')

def read_translations(file_path):
    translations = []
    with open(file_path, mode='r', newline='') as csvfile:
        reader = csv.DictReader(csvfile, delimiter='¨')
        for row in reader:
            translations.append(row)
    return translations

def update_database(translations):
    try:
        connection = pymysql.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        cursor = connection.cursor()

        for translation in tqdm(translations, desc="Atualizando banco de dados"):
            try:
                sql = f"UPDATE {translation['table']} SET {translation['field']} = %s WHERE {translation['field']} = %s"
                values = (translation['translated_string'], translation['original_string'])
                cursor.execute(sql, values)
            except pymysql.MySQLError as e:
                print(f"Erro ao executar a query para {translation['table']} com os valores {values}: {e}")

        connection.commit()
    except pymysql.MySQLError as e:
        print(f"Erro ao conectar ao banco de dados: {e}")
    finally:
        if connection and connection.open:
            cursor.close()
            connection.close()
            print("Conexão MySQL fechada.")

if __name__ == "__main__":
    translations = read_translations('/usr/src/app/final_translated_strings.csv')
    update_database(translations)

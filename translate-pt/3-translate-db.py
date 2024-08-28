import csv
from configparser import ConfigParser
import mysql.connector
from mysql.connector import Error
from tqdm import tqdm

def read_translations(file_path):
    translations = []
    with open(file_path, mode='r', newline='') as csvfile:
        reader = csv.DictReader(csvfile, delimiter='¨')
        for row in reader:
            translations.append(row)
    return translations

def read_db_config(config_file):
    parser = ConfigParser()
    parser.read(config_file)
    db_config = {
        'host': parser.get('mysql', 'host'),
        'database': parser.get('mysql', 'database'),
        'user': parser.get('mysql', 'user'),
        'password': parser.get('mysql', 'password')
    }
    return db_config


def update_database(translations, config):
    try:
        connection = mysql.connector.connect(**config)
        cursor = connection.cursor()
        
        for translation in tqdm(translations, desc="Atualizando banco de dados"):
            try:
                sql = f"UPDATE {translation['table']} SET {translation['field']} = %s WHERE {translation['field']} = %s"
                values = (translation['translated_string'], translation['original_string'])
                cursor.execute(sql, values)
            except Error as e:
                print(f"Erro ao executar a query para {translation['table']} com os valores {values}: {e}")
                
        connection.commit()
    except Error as e:
        print(f"Erro ao conectar ao banco de dados: {e}")
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("Conexão MySQL fechada.")



if __name__ == "__main__":
    translations = read_translations('final_translated_strings.csv')
    db_config = read_db_config('config.ini')
    update_database(translations, db_config)

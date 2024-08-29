import configparser
import csv
import mysql.connector

def read_config(file_path):
    config = configparser.ConfigParser()
    config.read(file_path)
    return config['mysql']

def read_tables_and_fields(file_path):
    tables_fields = []
    with open(file_path, mode='r', newline='') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=',')
        for row in reader:
            tables_fields.append((row['table'], row['field']))
    return tables_fields

def extract_strings(cursor, table, field):
    query = f"SELECT {field} FROM {table}"
    cursor.execute(query)
    results = cursor.fetchall()
    return [str(row[0]) for row in results if isinstance(row[0], str)]

def write_results_to_csv(output_file, results):
    with open(output_file, mode='w', newline='') as csvfile:
        fieldnames = ['table', 'field', 'original_string', 'translated_string']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames, delimiter='¨', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
        writer.writeheader()
        for result in results:
            writer.writerow(result)

def main():
    config = read_config('config.ini')
    tables_and_fields = read_tables_and_fields('tables_and_fields.csv')

    connection = mysql.connector.connect(
        host=config['host'],
        user=config['user'],
        password=config['password'],
        database=config['database']
    )

    cursor = connection.cursor()

    results = []
    for table, field in tables_and_fields:
        strings = extract_strings(cursor, table, field)
        for string in strings:
            results.append({'table': table, 'field': field, 'original_string': string, 'translated_string': string})

    cursor.close()
    connection.close()

    write_results_to_csv('extracted_strings.csv', results)

if __name__ == "__main__":
    main()

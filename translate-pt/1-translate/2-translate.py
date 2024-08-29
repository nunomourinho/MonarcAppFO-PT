import csv
import openai
from tqdm import tqdm
import configparser

# Leia a chave de API do arquivo config.ini
config = configparser.ConfigParser()
config.read('config.ini')
openai.api_key = config['openai']['api_key']

def read_csv(file_path):
    data = []
    with open(file_path, mode='r', newline='') as csvfile:
        reader = csv.DictReader(csvfile, delimiter='¨', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
        seen = set()
        for row in reader:
            key = f"{row['table']}¨{row['field']}¨{row['original_string']}"
            if key not in seen:
                seen.add(key)
                data.append(row)
    return data

def read_cache(cache_file):
    cache = {}
    try:
        with open(cache_file, mode='r', newline='') as csvfile:
            reader = csv.DictReader(csvfile, delimiter='¨', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
            for row in reader:
                key = f"{row['table']}¨{row['field']}¨{row['original_string']}"
                cache[key] = row['translated_string']
    except FileNotFoundError:
        pass
    return cache

def translate_text(text, retries=7):
    original_length = len(text)
    min_length = int(original_length * 0.7)
    max_length = int(original_length * 1.3)

    for attempt in range(retries):
        try:
            response = openai.Completion.create(
                engine="gpt-4",
                prompt=(
                    f"Translate the following text to European Portuguese, keeping the translation approximately the same length and text structure, considering the context of "
                    f"information security (ISO 27001,27002), GPDR, cybersecurity, and risk management: {text}"
                ),
                max_tokens=100,
                temperature=0.3
            )
            translated_text = response.choices[0].text.strip()
            translated_length = len(translated_text)

            if min_length <= translated_length <= max_length:
                return translated_text
            else:
                print(f"Translated text length {translated_length} is outside the acceptable range ({min_length}-{max_length}). Retrying...")

        except Exception as e:
            print(f"Error translating '{text}': {e}")

    print("Max retries reached. Skipping text.")
    return None  # Return None if translation fails

def translate_strings(data, cache, retries=3):
    translated_data = []
    for row in tqdm(data, desc="Translating strings", unit="strings"):
        key = f"{row['table']}¨{row['field']}¨{row['original_string']}"
        if key in cache:
            row['translated_string'] = cache[key]
            translated_data.append(row)
        else:
            translated = translate_text(row['original_string'], retries=retries)
            if translated:
                row['translated_string'] = translated
                cache[key] = translated
                translated_data.append(row)
                print(f"Translated '{row['original_string']}' to '{translated}'")
            else:
                print(f"Skipping '{row['original_string']}' due to failed translation.")
    return translated_data

def write_results_to_csv(output_file, data):
    with open(output_file, mode='w', newline='') as csvfile:
        fieldnames = ['table', 'field', 'original_string', 'translated_string']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames, delimiter='¨', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
        writer.writeheader()
        for row in data:
            writer.writerow(row)

def update_cache_file(cache_file, cache):
    with open(cache_file, mode='w', newline='') as csvfile:
        fieldnames = ['table', 'field', 'original_string', 'translated_string']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames, delimiter='¨', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
        writer.writeheader()
        for key, translated_string in cache.items():
            table, field, original_string = key.split('¨')
            writer.writerow({'table': table, 'field': field, 'original_string': original_string, 'translated_string': translated_string})

# Load cache
cache = read_cache('translated_strings.csv')

# Read input data
data = read_csv('extracted_strings.csv')

# Translate missing strings and update cache
translated_data = translate_strings(data, cache)

# Write final results to a new CSV
write_results_to_csv('final_translated_strings.csv', translated_data)

# Update cache file
update_cache_file('translated_strings.csv', cache)

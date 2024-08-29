import pandas as pd
from deep_translator import GoogleTranslator
from flask import Flask, request, render_template, redirect, url_for
import os
import openai
import configparser

# Carregar a configuração do arquivo config.ini
config = configparser.ConfigParser()
config.read('config.ini')
openai.api_key = config['openai']['api_key']

# Definir o caminho do arquivo CSV
file_name = 'final_translated_strings.csv'
file_path = os.path.join(os.getcwd(), file_name)
index_file_name = 'current_index.txt'
index_file_path = os.path.join(os.getcwd(), index_file_name)

# Carregar os dados do CSV com o separador ¨
df = pd.read_csv(file_path, delimiter='¨')

# Inicializar o tradutor
translator = GoogleTranslator(source='en', target='pt')

# Inicializar variáveis de navegação
current_index = 0

# Função para carregar o índice atual
def load_current_index():
    global current_index
    if os.path.exists(index_file_path):
        with open(index_file_path, 'r') as f:
            current_index = int(f.read().strip())
    else:
        current_index = 0

# Função para salvar o índice atual
def save_current_index():
    with open(index_file_path, 'w') as f:
        f.write(str(current_index))

# Carregar o índice atual
load_current_index()

# Função para salvar o CSV atualizado
def save_csv():
    df.to_csv(file_path, index=False, sep='¨')

# Função para tradução utilizando GPT-4
def translate_text(text, retries=7):
    for attempt in range(retries):
        try:
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "Você é um tradutor especializado em segurança informática, gestão de risco e RGPD."},
                    {"role": "user", "content": f"Traduza o seguinte texto para português de Portugal: {text}"}
                ],
                max_tokens=100,
                temperature=0.3
            )
            translated_text = response.choices[0].message['content'].strip()
            return translated_text

        except Exception as e:
            print(f"Error translating '{text}': {e}")

    print("Max retries reached. Skipping text.")
    return None  # Return None if translation fails

# Inicializar a aplicação Flask
app = Flask(__name__)

@app.route('/')
def index():
    global current_index
    record = df.loc[current_index]
    return render_template('index.html', record=record, index=current_index, total=len(df))

@app.route('/next', methods=['POST'])
def next_record():
    global current_index
    new_translation = request.form['translated_string']
    df.loc[current_index, 'translated_string'] = new_translation
    save_csv()
    if current_index < len(df) - 1:
        current_index += 1
    save_current_index()
    return redirect(url_for('index'))

@app.route('/previous', methods=['POST'])
def previous_record():
    global current_index
    new_translation = request.form['translated_string']
    df.loc[current_index, 'translated_string'] = new_translation
    save_csv()
    if current_index > 0:
        current_index -= 1
    save_current_index()
    return redirect(url_for('index'))

@app.route('/edit', methods=['POST'])
def edit_record():
    global current_index
    new_translation = request.form['translated_string']
    df.loc[current_index, 'translated_string'] = new_translation
    save_csv()
    return redirect(url_for('index'))

@app.route('/auto_translate')
def auto_translate():
    global current_index
    original_text = df.loc[current_index, 'original_string']
    for attempt in range(5):  # Tentar até 5 vezes
        try:
            translation = translator.translate(original_text)
            df.loc[current_index, 'translated_string'] = translation
            save_csv()
            break
        except Exception as e:
            print("Erro ao traduzir (tentativa {}): {}".format(attempt + 1, e))
    return redirect(url_for('index'))

@app.route('/gpt_translate')
def gpt_translate():
    global current_index
    original_text = df.loc[current_index, 'original_string']
    translated_text = translate_text(original_text)
    if translated_text:
        df.loc[current_index, 'translated_string'] = translated_text
        save_csv()
    return redirect(url_for('index'))

@app.route('/save')
def save():
    save_csv()
    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)

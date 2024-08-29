import pandas as pd
from googletrans import Translator
from prompt_toolkit import prompt
from prompt_toolkit.application import Application
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.shortcuts import message_dialog
from prompt_toolkit.patch_stdout import patch_stdout
from prompt_toolkit.widgets import TextArea, Dialog, Label, Button
from prompt_toolkit.layout import Layout, HSplit
import asyncio
import os
import time

# Definir o caminho do arquivo CSV
file_name = 'final_translated_strings.csv'
file_path = os.path.join(os.getcwd(), file_name)
index_file_name = 'current_index.txt'
index_file_path = os.path.join(os.getcwd(), index_file_name)

# Carregar os dados do CSV com o separador ¨
df = pd.read_csv(file_path, delimiter='¨')

# Inicializar o tradutor
translator = Translator()

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

# Função para exibir o menu
def display_menu():
    print("\nMenu de Opções:")
    print("n - Próximo registro")
    print("p - Registro anterior")
    print("e - Editar tradução")
    print("a - Tradução automática")
    print("s - Salvar CSV")
    print("q - Sair do programa")

# Função para exibir o registro atual
def display_record():
    global current_index
    print("\nRegistro {} de {}".format(current_index + 1, len(df)))
    print("Original String: {}".format(df.loc[current_index, 'original_string']))
    print("Translated String: {}".format(df.loc[current_index, 'translated_string']))
    print("\n\n")


# Função para tradução automática
def auto_translate():
    global current_index
    original_text = df.loc[current_index, 'original_string']
    for attempt in range(5):  # Tentar até 5 vezes
        try:
            translation = translator.translate(original_text, src='en', dest='pt')
            df.loc[current_index, 'translated_string'] = translation.text
            df.to_csv(file_path, index=False, sep='¨')
            print("Tradução automática realizada: {}".format(translation.text))
            break
        except Exception as e:
            print("Erro ao traduzir (tentativa {}): {}".format(attempt + 1, e))
            time.sleep(1)  # Esperar 1 segundo antes de tentar novamente

# Funções de navegação
def next_record():
    global current_index
    if current_index < len(df) - 1:
        current_index += 1
    save_current_index()
    display_menu()
    display_record()

def previous_record():
    global current_index
    if current_index > 0:
        current_index -= 1
    save_current_index()
    display_menu()
    display_record()

# Função para editar tradução manualmente
async def edit_translation():
    global current_index
    original_string = df.loc[current_index, 'original_string']
    current_translation = df.loc[current_index, 'translated_string']
    
    text_area = TextArea(text=current_translation, multiline=True, wrap_lines=True)
    
    def accept():
        new_translation = text_area.text
        if new_translation:
            df.loc[current_index, 'translated_string'] = new_translation
            df.to_csv(file_path, index=False, sep='¨')
            print("Tradução atualizada para: {}".format(new_translation))
        app.exit()  # Sair da aplicação de edição e voltar ao menu principal

    dialog_box = Dialog(
        title='Editar Tradução',
        body=HSplit([Label(text='Original String:'), TextArea(text=original_string, multiline=True, wrap_lines=True, read_only=True), Label(text='Nova tradução:'), text_area]),
        buttons=[Button(text='OK', handler=accept)]
    )

    layout = Layout(dialog_box)
    app = Application(layout=layout, full_screen=True)
    await app.run_async()

# Função para salvar o CSV atualizado
async def save_csv():
    df.to_csv(file_path, index=False, sep='¨')
    await message_dialog(title='Salvar', text='CSV atualizado salvo com sucesso!').run_async()

# Função principal para iniciar a interface
async def main():
    display_menu()
    display_record()
    bindings = KeyBindings()

    @bindings.add('q')
    def _(event):
        "Sair do programa."
        event.app.exit()

    @bindings.add('n')
    def _(event):
        "Próximo registro."
        next_record()

    @bindings.add('p')
    def _(event):
        "Registro anterior."
        previous_record()

    @bindings.add('e')
    async def _(event):
        "Editar tradução."
        await edit_translation()
        display_menu()
        display_record()

    @bindings.add('a')
    def _(event):
        "Tradução automática."
        auto_translate()
        display_menu()
        display_record()

    @bindings.add('s')
    async def _(event):
        "Salvar CSV."
        await save_csv()
        display_menu()

    app = Application(key_bindings=bindings, full_screen=False)

    with patch_stdout():
        await app.run_async()

if __name__ == "__main__":
    asyncio.run(main())

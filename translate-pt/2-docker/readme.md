
1) Editar ficheiro .env e escolher boas palavras passe para este projecto
2) Para executar:

```
docker-compose build
docker-compose up -d
```

Aguardar que todo o sistema arranque. Demora vários minutos

Depois entrar com o utilizador por defeito: admin@admin.localhost com a palavra passe admin


3) Para traduzir, primeiro edite os modelos existentes na pasta helper/pt. Altere apenas logos e imagem. Depois execute:
```
bash traduz-pt.sh
```


4) Pra usar as traduções, escolher no interface a lingua portuguesa. Quando se cria o modelo de análise escolher a lingua inglesa

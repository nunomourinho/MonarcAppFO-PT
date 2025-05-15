```
apt install git docker-compose nano -y
git clone 
```


1) Editar ficheiro .env e escolher boas palavras passe para este projecto
2) Para executar:

```
docker-compose build
docker-compose up
```

Aguardar que todo o sistema arranque. Demora vários minutos. Quando todas as migrações estiverem concluidas, tecle em Ctrl+C para parar o docker. Depois execute:

```
docker-compose up -d
```

Depois entrar com o utilizador por defeito: admin@admin.localhost com a palavra passe admin


3) Para traduzir, primeiro edite os modelos existentes na pasta helper/pt. Altere apenas logos e imagem. Depois execute:
```
bash traduz-pt.sh
```


4) Para usar as traduções, escolher no interface a lingua portuguesa. Quando se cria o modelo de análise escolher a lingua inglesa

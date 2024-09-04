#!/bin/bash

# Nome do diretório para salvar o backup
DATA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="docker_backup_$DATA"
COMPOSE_FILE="docker-compose.yml"

# Verificar se o ficheiro docker-compose.yml existe
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Ficheiro $COMPOSE_FILE não encontrado!"
    exit 1
fi

# Criar diretório para os backups
mkdir -p "$BACKUP_DIR"

echo "Backup de containers e volumes definidos em $COMPOSE_FILE"

# Fazer backup das imagens Docker (salva em arquivos .tar)
echo "Exportando imagens Docker..."
docker-compose config | grep "image:" | awk '{print $2}' | while read -r image; do
    image_name=$(echo "$image" | sed 's/\//_/g' | sed 's/:/_/g')
    docker save -o "$BACKUP_DIR/${image_name}.tar" "$image"
done

# Fazer backup dos volumes
echo "Exportando volumes Docker..."
docker volume ls -q | while read -r volume; do
    if [ ! -z "$volume" ]; then
        echo "Exportando volume: $volume"
        docker run --rm -v "${volume}:/volume" -v "$(pwd)/$BACKUP_DIR:/backup" alpine tar -czf "/backup/${volume}.tar.gz" -C /volume .
    fi
done

echo "Backup completo! Verifique a pasta $BACKUP_DIR para os ficheiros."

# Informar que o backup foi concluído
echo "Backup realizado com sucesso no diretório: $BACKUP_DIR"

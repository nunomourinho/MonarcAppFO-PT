#!/bin/bash

# Verifica se foi fornecido o diretório de backup como parâmetro
if [ -z "$1" ]; then
    echo "Uso: $0 <diretório_de_backup>"
    exit 1
fi

# Diretório de backup passado como argumento
BACKUP_DIR="$1"

# Verificar se o diretório de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Diretório de backup $BACKUP_DIR não encontrado!"
    exit 1
fi

# Função para restaurar as imagens Docker
restore_images() {
    echo "Restaurando imagens Docker..."
    for image_tar in "$BACKUP_DIR"/*.tar; do
        if [ -f "$image_tar" ]; then
            echo "Restaurando imagem: $(basename "$image_tar")"
            docker load -i "$image_tar"
        fi
    done
}

# Função para restaurar volumes Docker
restore_volumes() {
    echo "Restaurando volumes Docker..."
    for volume_tar in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$volume_tar" ]; then
            volume_name=$(basename "$volume_tar" .tar.gz)
            echo "Restaurando volume: $volume_name"
            
            # Criar o volume se não existir
            if [ -z "$(docker volume ls -q -f name="$volume_name")" ]; then
                docker volume create "$volume_name"
            fi

            # Restaurar os dados no volume
            docker run --rm -v "${volume_name}:/volume" -v "$(pwd)/$BACKUP_DIR:/backup" alpine sh -c "tar -xzf /backup/${volume_name}.tar.gz -C /volume"
        fi
    done
}

# Função para re-subir os containers com docker-compose
restart_containers() {
    if [ -f "docker-compose.yml" ]; then
        echo "Reiniciando containers com docker-compose..."
        docker-compose up -d
    else
        echo "Arquivo docker-compose.yml não encontrado no diretório atual. Containers não serão reiniciados."
    fi
}

# Executar as funções
restore_images
restore_volumes
restart_containers

echo "Restauração concluída!"

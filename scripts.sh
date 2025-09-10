#!/bin/bash

# --- Cores para o terminal ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor

cd "$(dirname "$0")"

# --- Funções ---

check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Erro: O Docker não parece estar em execução.${NC}"
        exit 1
    fi
}

setup_environment() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Configurando o ambiente pela primeira vez...${NC}"
        read -p "Digite o e-mail para o usuário: " ADMIN_EMAIL
        read -s -p "Digite a senha para o usuário: " ADMIN_PASSWORD
        echo

        cat > .env << EOL
N8N_INITIAL_OWNER_EMAIL=${ADMIN_EMAIL}
N8N_INITIAL_OWNER_PASSWORD=${ADMIN_PASSWORD}
GENERIC_TIMEZONE=America/Sao_Paulo
WEBHOOK_URL=http://localhost:5678/
EOL
        echo -e "${GREEN}Arquivo .env criado com as configurações corretas!${NC}"
    fi

    if [ ! -d ./n8n-data ]; then
        echo "Criando o diretório ./n8n-data..."
        mkdir ./n8n-data
        echo "Corrigindo permissões do diretório (pode pedir sua senha)..."
        sudo chown -R 1000:1000 ./n8n-data
        echo -e "${GREEN}Permissões corrigidas!${NC}"
    fi
}

show_help() {
    echo "Uso: ./scripts.sh [comando]"
    echo
    echo "Comandos:"
    echo -e "  ${GREEN}start${NC}   - Inicia o n8n."
    echo -e "  ${RED}stop${NC}    - Para o n8n."
    echo -e "  ${YELLOW}logs${NC}    - Mostra os logs do n8n."
    echo -e "  ${RED}clean${NC}   - Apaga TUDO (dados e configurações)."
}

# --- Lógica Principal ---
case "$1" in
    start)
        check_docker
        setup_environment
        echo -e "${GREEN}Iniciando o n8n...${NC}"
        docker-compose up -d
        ;;
    stop)
        check_docker
        echo -e "${YELLOW}Parando o n8n...${NC}"
        docker-compose down
        echo -e "${GREEN}n8n parado.${NC}"
        ;;
    logs)
        check_docker
        docker-compose logs -f
        ;;
    clean)
        check_docker
        echo -e "${RED}ATENÇÃO: Isso irá apagar TUDO.${NC}"
        read -p "Tem certeza? [s/N]: " CONFIRM
        if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
            docker-compose down
            echo "Removendo diretório de dados (pode pedir sua senha)..."
            sudo rm -rf ./n8n-data
            rm -f .env
            echo -e "${GREEN}Ambiente limpo.${NC}"
        else
            echo "Limpeza cancelada."
        fi
        ;;
    *)
        show_help
        ;;
esac
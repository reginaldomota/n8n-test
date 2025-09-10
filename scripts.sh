#!/bin/bash
# Salve este conteúdo como scripts.sh

# --- Cores para o terminal ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor

# Muda para o diretório onde o script está localizado
cd "$(dirname "$0")"

# --- Funções ---

# Verifica se o Docker está em execução
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Erro: O Docker não parece estar em execução.${NC}"
        echo -e "${YELLOW}Por favor, inicie o Docker e tente novamente.${NC}"
        exit 1
    fi
}

# Configura o ambiente na primeira execução
setup_environment() {
    # Cria o arquivo .env se ele não existir
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Configurando o ambiente pela primeira vez...${NC}"
        read -p "Digite o e-mail para o usuário administrador: " ADMIN_EMAIL
        read -s -p "Digite a senha para o usuário administrador: " ADMIN_PASSWORD
        echo # Adiciona uma nova linha após a senha

        # Cria o arquivo .env
        cat > .env << EOL
N8N_INITIAL_OWNER_EMAIL=${ADMIN_EMAIL}
N8N_INITIAL_OWNER_PASSWORD=${ADMIN_PASSWORD}
GENERIC_TIMEZONE=America/Sao_Paulo
WEBHOOK_URL=http://localhost:5678/
EOL
        echo -e "${GREEN}Arquivo .env criado com sucesso!${NC}"
    fi

    # Cria o diretório de dados se ele não existir
    if [ ! -d ./n8n-data ]; then
        echo "Criando o diretório ./n8n-data..."
        mkdir ./n8n-data
        echo "Ajustando permissões do diretório (pode pedir sua senha)..."
        sudo chown -R 1000:1000 ./n8n-data
        echo -e "${GREEN}Permissões ajustadas!${NC}"
    fi
}

# Mostra a ajuda
show_help() {
    echo "Uso: ./scripts.sh [comando]"
    echo
    echo "Comandos:"
    echo -e "  ${GREEN}start${NC}   - Inicia o n8n em segundo plano."
    echo -e "  ${RED}stop${NC}    - Para o n8n."
    echo -e "  ${YELLOW}logs${NC}    - Mostra os logs do n8n em tempo real."
    echo -e "  ${RED}clean${NC}   - Apaga TODOS os dados e configurações do n8n."
    echo
}

# --- Lógica Principal ---
case "$1" in
    start)
        if [ ! -f docker-compose.yml ]; then
            echo -e "${RED}Erro: Arquivo 'docker-compose.yml' não encontrado.${NC}"
            exit 1
        fi
        check_docker
        setup_environment
        echo -e "${GREEN}Iniciando o n8n...${NC}"
        docker-compose up -d
        echo -e "${GREEN}n8n iniciado! Acesse em http://localhost:5678${NC}"
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
        echo -e "${RED}ATENÇÃO: Este comando irá apagar TUDO (workflows, credenciais, etc).${NC}"
        read -p "Tem certeza que deseja continuar? [s/N]: " CONFIRM
        if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
            echo "Parando os contêineres..."
            docker-compose down
            echo "Removendo diretório de dados (pode pedir sua senha)..."
            sudo rm -rf ./n8n-data
            echo "Removendo arquivo de configuração..."
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
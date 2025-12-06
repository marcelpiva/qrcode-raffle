#!/bin/bash
set -e

# Configuration
INSTANCE_NAME="nava-summit-sorteio"
REGION="us-east-1"
BUNDLE="nano_3_0"  # $3.50/month - 512MB RAM, 1 vCPU

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

VERSION=$(cat VERSION 2>/dev/null || echo "1.5.0")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lightsail Deploy v${VERSION} - \$3.50/mês${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI não encontrado. Instale com: brew install awscli${NC}"
    exit 1
fi

# Check if instance exists
echo -e "${BLUE}Verificando instância...${NC}"
INSTANCE_EXISTS=$(aws lightsail get-instance --instance-name ${INSTANCE_NAME} --region ${REGION} 2>/dev/null && echo "yes" || echo "no")

if [ "$INSTANCE_EXISTS" = "no" ]; then
    echo -e "${YELLOW}Criando instância Lightsail...${NC}"

    aws lightsail create-instances \
        --instance-names ${INSTANCE_NAME} \
        --availability-zone ${REGION}a \
        --blueprint-id nodejs \
        --bundle-id ${BUNDLE} \
        --region ${REGION}

    echo -e "${GREEN}✓ Instância criada${NC}"
    echo -e "${YELLOW}⏳ Aguardando instância ficar pronta...${NC}"

    # Poll for instance ready
    for i in {1..60}; do
        STATUS=$(aws lightsail get-instance --instance-name ${INSTANCE_NAME} --region ${REGION} --query 'instance.state.name' --output text 2>/dev/null)
        if [ "$STATUS" = "running" ]; then
            echo -e "${GREEN}✓ Instância pronta${NC}"
            break
        fi
        echo -n "."
        sleep 5
    done

    # Wait extra time for SSH to be ready
    echo -e "${YELLOW}⏳ Aguardando SSH...${NC}"
    sleep 30
fi

# Get instance IP
INSTANCE_IP=$(aws lightsail get-instance --instance-name ${INSTANCE_NAME} --region ${REGION} --query 'instance.publicIpAddress' --output text)
echo -e "${GREEN}IP: ${INSTANCE_IP}${NC}"

# Open ports
echo -e "${BLUE}Abrindo portas 80, 443, 3000...${NC}"
aws lightsail open-instance-public-ports \
    --instance-name ${INSTANCE_NAME} \
    --port-info fromPort=80,toPort=80,protocol=TCP \
    --region ${REGION} 2>/dev/null || true

aws lightsail open-instance-public-ports \
    --instance-name ${INSTANCE_NAME} \
    --port-info fromPort=443,toPort=443,protocol=TCP \
    --region ${REGION} 2>/dev/null || true

aws lightsail open-instance-public-ports \
    --instance-name ${INSTANCE_NAME} \
    --port-info fromPort=3000,toPort=3000,protocol=TCP \
    --region ${REGION} 2>/dev/null || true

# Get SSH key
KEY_PATH="$HOME/.ssh/lightsail-${INSTANCE_NAME}.pem"
if [ ! -f "$KEY_PATH" ]; then
    echo -e "${BLUE}Baixando chave SSH...${NC}"
    aws lightsail download-default-key-pair --region ${REGION} --query 'privateKeyBase64' --output text | base64 -d > "$KEY_PATH"
    chmod 600 "$KEY_PATH"
fi

# Build project
echo -e "${BLUE}Building projeto...${NC}"
npm run build

# Create deployment package (without macOS extended attributes)
echo -e "${BLUE}Criando pacote de deploy...${NC}"
COPYFILE_DISABLE=1 tar -czf deploy.tar.gz \
    .next \
    package.json \
    package-lock.json \
    prisma \
    public \
    next.config.ts \
    VERSION

echo -e "${GREEN}✓ Pacote criado: $(ls -lh deploy.tar.gz | awk '{print $5}')${NC}"

# Upload to instance
echo -e "${BLUE}Enviando para Lightsail...${NC}"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no deploy.tar.gz bitnami@${INSTANCE_IP}:/home/bitnami/

# Deploy on instance
echo -e "${BLUE}Instalando no servidor...${NC}"
ssh -T -i "$KEY_PATH" -o StrictHostKeyChecking=no bitnami@${INSTANCE_IP} << 'REMOTE'

cd /home/bitnami
mkdir -p app

# Preserve .env before extraction
if [ -f app/.env ]; then
    cp app/.env /tmp/.env.backup
fi

cd app

# Extract (overwrite all)
tar -xzf ../deploy.tar.gz
rm ../deploy.tar.gz

# Restore .env if backed up
if [ -f /tmp/.env.backup ]; then
    cp /tmp/.env.backup .env
    rm /tmp/.env.backup
    echo "✓ .env restaurado"
fi

# Create .env if not exists
if [ ! -f .env ]; then
    cat > .env << 'ENV'
DATABASE_URL="postgresql://neondb_owner:npg_f0AeWEHUn2Pj@ep-dry-scene-ahses04e-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require"
ADMIN_PASSWORD="navasummit@2025"
NODE_ENV=production
PORT=3000
ENV
    echo "✓ .env criado"
fi

# Install dependencies
echo "Instalando dependências..."
npm install --omit=dev

# Generate Prisma
echo "Gerando Prisma client..."
npx prisma generate

# Install PM2 globally if not present
if ! command -v pm2 &> /dev/null; then
    echo "Instalando PM2..."
    sudo npm install -g pm2
fi

# Start/restart with PM2
pm2 delete nava-sorteio 2>/dev/null || true
pm2 start npm --name "nava-sorteio" -- start
pm2 save

echo "✓ App rodando com PM2"

# === SETUP CADDY (porta 80 -> 3000) ===
if ! command -v caddy &> /dev/null; then
    echo "Instalando Caddy..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq caddy
fi

# Configure Caddy
sudo tee /etc/caddy/Caddyfile > /dev/null << 'CADDYFILE'
:80 {
    reverse_proxy localhost:3000
}
CADDYFILE

# Stop Apache if running (Bitnami default)
sudo /opt/bitnami/ctlscript.sh stop apache 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true
sudo systemctl disable apache2 2>/dev/null || true

# Start Caddy
sudo systemctl restart caddy
sudo systemctl enable caddy

echo "✓ Caddy configurado (porta 80 -> 3000)"
REMOTE

# Cleanup local
rm -f deploy.tar.gz

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deploy Completo!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "App URL: ${BLUE}http://${INSTANCE_IP}${NC}"
echo ""
echo -e "${YELLOW}Para HTTPS com domínio customizado:${NC}"
echo -e "1. Aponte seu domínio para ${INSTANCE_IP}"
echo -e "2. Edite /etc/caddy/Caddyfile no servidor:"
echo -e "   ssh -i $KEY_PATH bitnami@${INSTANCE_IP}"
echo -e "   sudo nano /etc/caddy/Caddyfile"
echo -e "   # Troque ':80' pelo seu domínio (ex: sorteio.nava.com.br)"
echo -e "   sudo systemctl reload caddy"
echo ""
echo -e "${YELLOW}Custo: ~\$3.50/mês${NC}"

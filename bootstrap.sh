#!/bin/bash

set -e

TIMEOUT=60  # segundos máximos para esperar container subir
COUNT=0

# Verifica se Docker já está instalado
if ! command -v docker &> /dev/null; then
  echo "[1/3] Docker não encontrado. Instalando manualmente..."
  sudo apt update
  sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io
else
  echo "[1/3] Docker já está instalado."
fi

# Verifica se Docker Compose v2 já está instalado
if ! docker compose version &> /dev/null; then
  echo "Instalando Docker Compose v2 (armhf)..."
  mkdir -p ~/.docker/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-armv7 -o ~/.docker/cli-plugins/docker-compose
  chmod +x ~/.docker/cli-plugins/docker-compose
else
  echo "Docker Compose já está instalado."
fi

# Permissões e grupo docker
if [ "$EUID" -eq 0 ]; then
  echo "[!] Rodando como root. Pule a configuração de grupo docker."
else
  CURRENT_USER=$(logname)
  if groups $CURRENT_USER | grep -q '\bdocker\b'; then
    echo "[✓] Usuário $CURRENT_USER já está no grupo docker."
  else
    echo "Adicionando $CURRENT_USER ao grupo docker..."
    sudo usermod -aG docker "$CURRENT_USER"
    echo "[!] Reinicie a sessão (ou o sistema) para aplicar as permissões do grupo docker."
  fi
fi

# Ambiente Python virtual local (caso rodando sem container)
echo "[+] Verificando ambiente virtual Python..."
sudo apt install -y python3-venv

if [ ! -d "venv" ]; then
  echo "[+] Criando ambiente virtual Python..."
  python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Subindo container com verificação
echo "[2/3] Subindo container..."
if docker compose up -d --build; then
  echo "[✔] Container iniciado com sucesso."
else
  echo "[✖] Erro ao iniciar o container. Verifique os logs."
  docker compose logs
  exit 1
fi

# Aguarda o container ficar ativo (com timeout)
echo -n "[3/3] Aguardando container iniciar... "
while ! docker ps --filter "name=hotspot-pix" --filter "status=running" | grep -q hotspot-pix; do
  sleep 1
  ((COUNT++))
  echo -n "."
  if [ $COUNT -ge $TIMEOUT ]; then
    echo "\n[✖] Timeout: container não iniciou em ${TIMEOUT}s"
    docker compose logs
    exit 1
  fi
  done

echo "\n[✔] Container em execução. Inicializando banco de dados..."
if docker compose exec hotspot python app/generate_vouchers.py --init; then
  echo "[✔] Banco de dados inicializado."
else
  echo "[✖] Falha ao inicializar o banco. Verifique se o container está rodando corretamente."
  docker compose logs
  exit 1
fi

echo "[✔] Setup Docker completo! Acesse http://<IP-da-placa>:5000"


# --- cron/hotspot.cron (mantido caso necessário fora do container) ---

# Expira vouchers a cada 1 minuto
* * * * * docker exec hotspot-pix python /app/app/expire_vouchers.py >> /app/logs/cron.log 2>&1


# --- setup-host.sh (modo direto no host, Raspbian compatível) ---

#!/bin/bash
set -e

echo "🚀 Iniciando setup completo do Hotspot PIX na Raspberry Pi..."

# 1. Atualiza e instala dependências do sistema
echo "🔧 Instalando pacotes do sistema..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv cups libcups2-dev \
                    git build-essential libjpeg-dev zlib1g-dev \
                    libfreetype6-dev liblcms2-dev libopenjp2-7-dev \
                    libtiff5-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev

# 2. Criação de ambiente virtual
echo "🐍 Criando ambiente virtual Python..."
cd "$(dirname "$0")"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 3. Inicializa banco de dados
echo "🗃️ Inicializando banco de dados SQLite..."
python app/generate_vouchers.py --init

# 4. Configura serviço systemd
echo "🛠️ Configurando serviço systemd..."
SERVICE_PATH="/etc/systemd/system/hotspot.service"
cat <<EOF | sudo tee $SERVICE_PATH > /dev/null
[Unit]
Description=Hotspot PIX Flask App
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/python app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hotspot
sudo systemctl restart hotspot

# 5. Configura CUPS e impressora Elgin i9
echo "🖨️ Configurando CUPS e impressora Elgin i9..."
sudo usermod -aG lpadmin $USER
sudo systemctl enable cups
sudo systemctl start cups

# O driver raw permite impressão direta sem formatação extra
sudo lpadmin -p elgin_i9 -E -v usb://Elgin/i9 -m raw || echo "⚠️ Verifique conexão da Elgin i9 via USB"

echo "✅ Setup concluído com sucesso!"
echo "🌐 Acesse: http://$(hostname -I | awk '{print $1}'):5000"

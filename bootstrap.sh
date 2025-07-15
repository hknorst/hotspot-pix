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
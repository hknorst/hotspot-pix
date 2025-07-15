#!/bin/bash

set -e

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

# Permissões
if [ -n "$SUDO_USER" ]; then
  echo "Adicionando $SUDO_USER ao grupo docker..."
  sudo usermod -aG docker "$SUDO_USER"
else
  echo "[!] Variável SUDO_USER não definida. Pule a alteração de grupo manualmente."
fi

# Subindo container com verificação
echo "[2/3] Subindo container..."
if docker compose up -d --build; then
  echo "[✔] Container iniciado com sucesso."
else
  echo "[✖] Erro ao iniciar o container. Verifique os logs."
  exit 1
fi

sleep 3

# Inicializando banco de dados com verificação
echo "[3/3] Inicializando banco de dados..."
if docker compose exec hotspot python generate_vouchers.py --init; then
  echo "[✔] Banco de dados inicializado."
else
  echo "[✖] Falha ao inicializar o banco. Verifique se o container está rodando corretamente."
  docker compose logs
  exit 1
fi

echo "[✔] Setup Docker completo! Acesse http://<IP-da-placa>:5000"
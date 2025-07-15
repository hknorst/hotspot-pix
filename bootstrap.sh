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
sudo usermod -aG docker $(whoami)
newgrp docker

echo "[2/3] Subindo container..."
docker compose up -d --build

sleep 3

echo "[3/3] Inicializando banco de dados..."
docker compose exec hotspot python generate_vouchers.py --init

echo "[✔] Setup Docker completo! Acesse http://<IP-da-placa>:5000"

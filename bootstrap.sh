#!/bin/bash

set -e

echo "[1/3] Instalando Docker e Docker Compose..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)
newgrp docker

echo "[2/3] Subindo container..."
docker compose up -d --build

sleep 3
echo "[3/3] Inicializando banco de dados..."
docker compose exec hotspot python generate_vouchers.py --init

echo "[✔] Setup Docker completo! Acesse http://<IP-da-placa>:5000"

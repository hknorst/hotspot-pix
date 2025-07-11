# Hotspot Pix – Acesso Wi-Fi com Pagamento via Pix

Sistema completo de hotspot com pagamento via Pix, desenvolvido para rodar em uma **Raspberry Pi** conectada à internet via **Starlink**, com **controle de acesso por vouchers temporários**, **impressão térmica com Elgin i9**, e **integração com MercadoPago**.

---

## 🚀 Funcionalidades

✅ Captive portal (via Nodogsplash)  
✅ Página de planos (1h, 3h, 24h)  
✅ Geração de QR Code Pix com MercadoPago  
✅ Liberação automática após pagamento  
✅ Impressão térmica do voucher (Elgin i9 via USB)  
✅ Validação por MAC/IP  
✅ Expiração automática do tempo  
✅ Interface leve com Flask e SQLite

---

## 🖥️ Requisitos

- Raspberry Pi 2/3/4
- Impressora térmica Elgin i9 (USB)
- Conta no [MercadoPago](https://www.mercadopago.com.br/)
- Internet via Starlink (ou outra)
- Docker + Docker Compose

---

## ⚙️ Como usar

### 1. Clone este repositório

```bash
git clone https://github.com/hknorst/hotspot-pix.git
cd hotspot-pix
```

### 2. Configure sua chave do MercadoPago

Abra `app.py` e insira sua `ACCESS_TOKEN`:

```python
ACCESS_TOKEN = "SUA_CHAVE_MERCADOPAGO"
```

### 3. Construa e inicie com Docker

```bash
docker-compose build
docker-compose up -d
```

---

## 📡 Como funciona o fluxo

1. Cliente conecta ao Wi-Fi gerenciado pela Raspberry Pi
2. Nodogsplash redireciona para `http://192.168.10.1:5000/`
3. Usuário escolhe o plano (1h, 3h, 24h)
4. Sistema gera um QR Code Pix
5. Após pagamento, o voucher é gerado e:
   - Pode ser impresso
   - Pode ser usado diretamente com link ou código

---

## 🖨️ Impressora Elgin i9

- Detectada via USB no Raspberry Pi
- Impressão via `python-escpos`
- Automática ao final do fluxo (ou opcional pelo botão "Imprimir")

---

## 📂 Estrutura do Projeto

```
hotspot-pix/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── app.py
├── generate_vouchers.py
├── print_voucher.py
├── validate.py
├── expire_vouchers.py
├── vouchers.db
├── templates/
│   ├── planos.html
│   ├── pagamento.html
│   └── voucher.html
└── static/
    └── qrcodes/
```

---

## ✍️ Licença

Projeto desenvolvido por [@hknorst](https://github.com/hknorst). Uso livre para fins educacionais, comunitários ou comerciais com créditos.
---

## 🛠️ Automação com Makefile

Este projeto inclui um `Makefile` para facilitar a configuração:

| Comando         | Ação                                                                 |
|----------------|----------------------------------------------------------------------|
| `make init`    | Cria o banco de dados e diretórios de QR codes                       |
| `make cron`    | Adiciona o `expire_vouchers.py` ao crontab (executa a cada minuto)   |
| `make run`     | Sobe o sistema com Docker                                            |
| `make stop`    | Derruba os containers                                                |
| `make logs`    | Mostra logs do container em tempo real                               |
| `make clean`   | Remove QR codes e o banco de dados                                   |
| `make rebuild` | Rebuilda e reinicia os containers                                    |

Execute os comandos na raiz do projeto com:

```bash
make init
make cron
make run
```

---

## 🔄 Inicialização automática com systemd

Para iniciar o sistema automaticamente no boot:

1. Copie o arquivo de serviço:
   ```bash
   sudo cp hotspot.service /etc/systemd/system/
   ```

2. Recarregue os daemons:
   ```bash
   sudo systemctl daemon-reexec
   sudo systemctl daemon-reload
   ```

3. Ative o serviço:
   ```bash
   sudo systemctl enable hotspot
   ```

4. Inicie manualmente:
   ```bash
   sudo systemctl start hotspot
   ```

Verifique o status com:
```bash
sudo systemctl status hotspot
```
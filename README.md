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
---

## 🌐 Redirecionamento do Nodogsplash para o Flask

Para usar o seu sistema Flask como o portal cativo completo (em vez da página splash.html interna do Nodogsplash), siga os passos abaixo:

### 🔧 1. Edite o arquivo de configuração do Nodogsplash

```bash
sudo nano /etc/nodogsplash/nodogsplash.conf
```

### ✏️ 2. Adicione ou edite a seguinte linha:

```conf
RedirectURL http://192.168.10.1:5000/
```

Isso faz com que qualquer dispositivo conectado ao Wi-Fi seja automaticamente redirecionado para a interface web do seu sistema Flask, onde o cliente pode escolher o plano, pagar e acessar com o voucher.

### 🔁 3. Reinicie o Nodogsplash

```bash
sudo systemctl restart nodogsplash
```

### ✅ 4. Teste o fluxo

1. Conecte um dispositivo ao Wi-Fi
2. O navegador abrirá automaticamente a URL `http://192.168.10.1:5000/`
3. O cliente verá a página de planos e poderá seguir com o pagamento via Pix
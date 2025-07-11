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
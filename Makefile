# Makefile para configurar o Hotspot Pix

init:
	@echo "🔧 Criando banco de dados e pastas necessárias..."
	mkdir -p static/qrcodes
	python3 app/generate_vouchers.py -n 0 -d 60

cron:
	@echo "⏱️  Adicionando expire_vouchers.py ao crontab..."
	(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 /app/expire_vouchers.py >> /var/log/hotspot-expire.log 2>&1") | crontab -

run:
	@echo "🚀 Iniciando aplicação Flask com Docker..."
	docker-compose up -d --build

stop:
	@echo "🛑 Parando containers..."
	docker-compose down

logs:
	docker-compose logs -f

clean:
	rm -rf static/qrcodes/*
	rm -f app/vouchers.db
	@echo "🧹 Limpeza completa."

rebuild:
	@echo "🔄 Rebuildando container..."
	docker-compose down
	docker-compose build
	docker-compose up -d
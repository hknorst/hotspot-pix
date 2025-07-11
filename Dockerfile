FROM python:3.9-slim

RUN apt-get update && apt-get install -y \
    libusb-1.0-0 \
    libjpeg62-turbo \
    build-essential \
    cups \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000
CMD ["python", "app.py"]
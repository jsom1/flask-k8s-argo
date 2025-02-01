# Utiliser une image Python légère
FROM python:3.9-slim

# Définir le répertoire de travail dans le container
WORKDIR /app

# Copier les fichiers nécessaires dans le container
COPY requirements.txt ./
COPY app ./app

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Exposer le port sur lequel l'application écoutera
EXPOSE 5000

# Lancer l'application
CMD ["python3", "app/main.py"]

# Utiliser une image Python légère
FROM python:3.9-slim

# Définir le répertoire de travail
WORKDIR /app
ENV PYTHONPATH=/app

# Copier les fichiers nécessaires
COPY requirements.txt ./
COPY app ./app
COPY tests ./tests

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Définir une variable d’environnement pour activer le mode TEST
ARG RUN_TESTS="false"

# Exposer le port 5000
EXPOSE 5000

# Exécuter les tests si RUN_TESTS=true, sinon démarrer l’application
CMD if [ "$RUN_TESTS" = "true" ]; then pytest tests/; else python3 app/main.py; fi


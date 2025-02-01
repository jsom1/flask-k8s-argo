---
title: "tets"
output: html_document
date: '2025-01-31'
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Projet DevOps « from scratch »

## Introduction
Ce projet vise à appliquer un workflow DevOps complet, de la création d’une application simple jusqu'à sa mise en production automatisée sur *Kubernetes* avec *GitOps*. Il inclut également les bonnes pratiques en matière de qualité, monitoring et sécurité.

## 📌 Objectif
Le projet est organisé en **2 parties** :

-	**La base** : dans un premier temps, le but sera de développer et automatiser le déploiement d’une application web minimaliste en suivant un workflow DevOps standard.
L’application, développée en Python avec *Flask*, sera contenue dans un container *Docker*, puis déployée sur un cluster *Kubernetes* via *MiniKube*, et gérée avec *Helm* et *ArgoCD*.

-	**Pour aller plus loin** : dans un second temps, le but sera d'améliorer la qualité, la sécurité et l’observabilité de l’application en intégrant des tests unitaires et d’intégration avec *Pytest*, ainsi qu’un système de monitoring et de logs basé sur *Prometheus*.

## 🛠 Stack technologique
- **Langage & Framework** : Python, Flask
- **Containerisation & Orchestration** : Docker, Kubernetes, Minikube
- **Déploiement & Automatisation** : Argo CD, Helm, Git
- **Qualité du code** : Pytest
- **Monitoring & Logs** : Prometheus

## 📖 Concepts abordés
- **CI/CD** : Intégration et déploiement continus
- **GitOps** : Gestion des déploiements via Git
- **Infrastructure as Code (IaC)** : Définition des infrastructures sous forme de code
- **Cloud-native** : Containerisation et microservices
- **Tests** : Unitaires et d’intégration
- **Logs & Monitoring**

---

# 🏗 Base : Déploiement d’une application Flask sur Kubernetes

## 📌 Objectifs
1. **Développement de l’application** : création d’une API Flask simple avec un  endpoint : GET / qui retourne le message « Hello from Flask in Kubernetes ! ».
2. **Containerisation avec Docker** : packaging de l’application sous forme d’image Docker pour garantir la portabilité et la reproductibilité.
3. **Déploiement statique sur Kubernetes** : création et gestion des ressources Kubernetes (deployment, service, namespace) avec des manifests YAML statiques.
4. **Déploiement dynamique avec Helm** : transformation des manifests statiques en templates Helm, pemettant un déploiement flexible et évolutif.
5. **Automatisation avec Argo CD** : mise en place d’une approche GitOps avec Argo CD pour surveiller un repo Git et déployer automatiquement les changements sur le cluster Kubernetes.

## 1️⃣ Développement de l’application (API Flask)

### Structure du projet

```bash
flask-k8s-argo/
│── app/
│   ├── main.py       # Code de l'API Flask
│   ├── __init__.py   # Pour que Python considère le dossier /app comme un module
│── requirements.txt  # Dépendances (Flask)
│── Dockerfile        # Fichier pour Docker
│── .gitignore
│── .git
```
On commence par créer le répertoire *flask-k8s-argo* et on passe dedans. On crée aussi les différents fichiers nécessaires :

```bash
mkdir flask-k8s-argo && cd flask-k8s-argo
mkdir app
touch app/main.py
touch app/__init__.py
touch requirements.txt
touch Dockerfile
touch .gitignore
```

Pour commiter sur Github, il faut encore initialiser un repo git (nécessaire aussi plus tard pour ArgoCD)

```bash
git init
```

Ensuite, on peut écrire le code de l'application.

### Code Flask (`app/main.py`)

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify(message="Hello from Flask in Kubernetes!")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Facultativement, on peut aussi spécifier le contenu du fichier *__init__.py* :

```python
# app/__init__.py
from flask import Flask

app = Flask(__name__)

from app import main  # Import du fichier main.py

```

### Installation des dépendances

Les dépendances requises sont listées dans le fichier *requirements.txt*. Actuellement, nous n'avons besoin que de Flask:

```bash
echo flask > requirements.txt
```
Ensuite, on peut installer les dépendances requises (Flask)

```bash
pip install -r requirements.txt
```

Si ça ne marche pas, par exemple parce que *pip* n'est pas dans le *PATH*, on peut aussi installer Flask via Python :

```bash
python3 -m pip install -user flask
```

### Test en local

A ce stade, on peut déjà vérifier que l'application fonctionne :

```bash
python3 app/main.py
```
Le message suivant devrait apparaîte : "*Running on http://127.0.0.1:5000*". On peut soit se rendre à cette URL dans un browser, ou simplement utiliser *curl* :

```bash
curl http://127.0.0.1:5000
```
Le message "*Hello from Flask in Kubernetes!*" devrait s'afficher.

---

## 2️⃣ Containerisation avec Docker

### Dockerfile

Maintenant qu'on sait que l'application fonctionne, on peut la containeriser. On commence par créer le Dockerfile :

```dockerfile
# Utiliser une image Python légère
FROM python:3.9-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers nécessaires
COPY requirements.txt ./
COPY app ./app

# Installer Flask
RUN pip install --no-cache-dir -r requirements.txt

# Exposer le port 5000 sur lequel l’application écoutera
EXPOSE 5000

# Lancer l'application
CMD ["python3", "app/main.py"]
```

### Build & run

Maintenant, ce Dockerfile peut être utilisé pour créer une image Docker qu'on appellera *flask-app* :

```bash
docker build -t flask-app .
```
Les images existantes sont visibles avec la commande suivante :

```bash
docker images
```
Finalement, on peut lancer le container :

```bash
docker run -p 5000:5000 flask-app
```

On devrait à nouveau avoir le message "*Hello from Flask in Kubernetes!*".

---

## 3️⃣ Déploiement statique sur Kubernetes avec Minikube

### Installation & démarrage

Maintenant qu'on a un container Docker qui fonctionne, on peut le déployer dans un cluster Kubernetes. On peut utiliser GKE (Google Kubernetes Engine, payant et accessible depuis l'extérieur) ou Minikube (gratuit, local). On utilisera ici Minikube.

```bash
brew install minikube
minikube version
```
Si l'installation s'est bien passée, on peut démarrer un cluster localement :

```bash
minikube start
```
On vérifie l'état du cluster:

```bash
kubectl get nodes
```
Si *Status=Ready*, le cluster est opérationnel. On peut créer un namespace pour l'application. Ceci permet de la séparer d'autres applications éventuelles, et donc de bien gérer les ressources Kubernetes.

### Création du namespace Kubernetes

```bash
kubectl create namespace flask-app
kubectl get namespaces
```
Le namespace *flask-app* devrait apparaître dans la liste. Les namespaces suivants sont créés automatiquement par Kubernetes :

-	Default : namespace par défaut si on ne précise rien au moment du déploiement. Toutes les ressources sans namespace explicite iront ici
-	Kube-node-lease : gère la communication entre les nœuds du cluster pour savoir s’ils sont actifs
-	Kube-public : contient des ressources accessibles publiquement
-	Kube-system : namespace où tournent les services de k8s (DNS, scheduluer, API server, etc…)

Maintenant que Minikube tourne et qu’on a un namespace, on peut passer au déploiement.

### Manifests YAML (`manifests/`)

Pour le déploiement, il nous faut deux manifests YAML :

-	**Deployment** : gère la création et la mise à jour du container Flask
-	**Service** : expose l’application pour qu’elle soit accessible

On place ces manifests dans un dossier *manifests*. La stucture du projet mis à jour est la suivante :

```bash
flask-k8s-argo/
│── app/ 
	│── main.py
	│── __init__.py
│── manifests/ 
	│── deployment.yaml
	│── service.yaml
│── requirements.txt 
│── Dockerfile 
│── .gitignore
│── .git
```

On peut donc créer le dossier, passer dedans et créer les manifests : 

```bash
mkdir manifests && cd manifests
touch deployment.yaml service.yaml
```

Le contenu des manifests est le suivant :

#### `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  namespace: flask-app
  labels:
    app: flask-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
        - name: flask-app
          image: flask-app
          imagePullPolicy: Never
          ports:
            - containerPort: 5000
```

Le paramètre *imagePullPolicy: Never* force Kubernetes à utiliser l'image locale.

#### `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-service
  namespace: flask-app
spec:
  selector:
    app: flask-app
  type: NodePort
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
      nodePort: 30007
```

On définit ici un service de type NodePort en dur (normalement Kubernetes assigne automatiquement un port entre 30'000 et 32'767). Un NodePort expose un port spécifique sur tous les noeuds du cluster, ce qui permet un accès externe à une application.

Un noeud est une machine (physique ou virtuelle) qui exécute les applications Kubernetes.
Un Service NodePort ouvre un port sur tous les *workers nodes* du cluster pour permettre un accès externe.
Dans Minikube, tout est sur une seule machine, donc ça fonctionne localement.

Il faut noter que NodePort est pratique pour tester localement, mais pas recommandé en production. En production, on utiliserait plutôt des *ingress controllers* ou *LoadBalancers*.

Une fois les manifests créés, on peut les appliquer dans Kubernetes.

### Application des manifests

Concrètement, Kubernetes va lire ces manifests et créer les ressources correspondantes.

```bash
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
```
Kubernetes crée donc un déploiement qui gère le container Flask, et un service qui permet d'y accéder. On vérifie que tout fonctionne correctement :

```bash
kubectl get pods -n flask-app
kubectl get services -n flask-app
```

On vérifie finalement que l'application tourne bien dans Kubernetes :

```bash
Kubectl get services -n flask-app
```

Le résultat de cette commande devrait ressembler à ceci :

| NAME          | TYPE      | CLUSTER-IP       | EXTERNAL-IP | PORT(S)       | AGE   |
|--------------|----------|------------------|-------------|--------------|------|
| flask-service | NodePort | 10.111.255.215   | <none>      | 80:30007/TCP | 2m47s |

L'adresse IP du cluster, *10.111.255.215*, n'est accessible que depuis l'intérieur du cluster. *Port(s)=80:300007/TCP* indique que le port 30007 du noeud (le NodePort accessible depuis l'extérieur) est redirigé vers le port 80 du service, qui est lui-même redirigé vers le port 5000 de l'application Flask.

### Accès à l'application

A ce stade, il y a deux manière d'accéder à l'application :

1. La méthode *port-forward* de kubectl permet de rediriger temporairement un port local vers l'application :

```bash
kubectl port-forward -n flask-app pod/$(kubectl get pod -n flask-app -o jsonpath='{.items[0].metadata.name}') 5000:5000
```
L'application devrait être accessible à l'adresse *http://127.0.0.1:5000*.

2. La méthode *service* de Minikube permet d'exposer directement un service sur localhost :

```bash
minikube service flask-service -n flask-app --url
```

Cette commande renvoie une URL temporaire, aussi utilisable dans un browser ou via *curl*.

Actuellement, l'application tourne bien dans Kubernetes avec des manifests YAML statiques. 

---

## 4️⃣ Déploiement dynamique avec Helm

Le "problème" des manifests statiques est que si on veut modifier des valeurs comme le nombre de *replicas*, l'image Docker, le NodePort, etc..., il faudrait aller modifier ces fichiers manuellement à chaque changement.

*Helm* permet de transformer ces fichiers YAML en **templates**, ce qui permet une configuration dynamique et non plus statique. Cela se fait grâce au fichier *values.yaml*.

### Installation de Helm

*Helm* peut être installé avec la commande suivante (sur Mac) :

```bash
brew install helm
helm version
```

### Structure du Chart Helm

Une fois installé, la commande suivante crée un **chart Helm** dans le répertoire du projet (nommé ici *flask-chart*) :

```bash
helm create flask-chart 
```

Des dossiers et fichiers sont automatiquement créés, et la nouvelle structure du projet est la suivante :

```bash
flask-k8s-argo/
│── app/ 
│   ├── main.py
│   ├── __init__.py
│── flask-chart/              # Dossier du chart Helm
│   ├── charts/               # Sous-charts Helm (non utilisé ici)
│   ├── templates/            # Contient les templates YAML pour Kubernetes
│   │   ├── deployment.yaml   # Template pour le Deployment
│   │   ├── service.yaml      # Template pour le Service
│   │   ├── _helpers.tpl      # Fonctions réutilisables pour Helm
│   │   ├── NOTES.txt         # Message affiché après installation du chart
│   │   ├── hpa.yaml          # Pour le scaling automatique (non utilisé ici)
│   │   ├── ingress.yaml      # Pour exposer via un ingress controller (optionnel)
│   ├── values.yaml           # Contient les variables dynamiques
│   ├── Chart.yaml            # Métadonnées du Chart (nom, version, description)
│   ├── .helmignore           # Fichiers à ignorer (comme .gitignore)
│── manifests/                # Ce dossier deviendra obsolète avec Helm)
│   ├── deployment.yaml       # (sera remplacé par Helm)
│   ├── service.yaml          # (sera remplacé par Helm)
│── requirements.txt	
│── Dockerfile		
│── .gitignore			
│── .git

```

Le fichier *values.yaml* contiendra les variables dynamiques (comme le nom du container, les *replicas*, l'image Docker, etc...). Ces fichiers sont déjà remplis avec des explications quant à leur utilisation.

Il faut modifier les fichiers suivants :

#### `Chart.yaml`

```yaml
apiVersion: v2
name: flask-chart
description: A Helm chart for deploying a Flask app on Kubernetes

type: application

# Version du chart Helm
version: 0.1.0

# Version de l'application
appVersion: "1.0.0"
```

#### `values.yaml`

```yaml
replicaCount: 1

image:
  repository: flask-app
  tag: latest
  pullPolicy: Never

serviceAccount: create: false

ingress:
  enabled: false

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80

service:
  type: NodePort
  port: 80
  targetPort: 5000
  nodePort: 30007

resources: {}

nodeSelector: {}

tolerations: []

affinity: {}
```

#### `templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}-app
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-app
    spec:
      containers:
        - name: flask-app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
```

#### `templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-service
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ .Release.Name }}-app
  type: {{ .Values.service.type }}
  ports:
    - protocol: TCP
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      nodePort: {{ .Values.service.nodePort }}
```

### Installation du Chart Helm

A ce stade, l'application est prête à être redéployée avec *Helm* :

```bash
helm install flask-app ./flask-chart --namespace flask-app
helm list -n flask-app
```

Finalement, l'URL d'accès à l'application peut être récupérée avec la commande suivante :

```bash
minikube service flask-app-service -n flask-app –url
```

---

## 5️⃣ Automatisation avec Argo CD

Actuellement, on a un déploiement dynamique avec Helm, mais l’application est toujours déployée manuellement avec la commande *helm install*.
L’objectif est maintenant d’automatiser enitèrement les déploiements en suivant une approche GitOps grâce à Argo CD. L'idée est qu'Argo CD automatise le déploiement de l'application en se basant sur un repo Git comme unique source de vérité ; il assure que ce qui est déployé correspond toujours à l'état défini dans Git.

C'est donc un bon moment pour créer un repo Git (si pas déjà le cas). 

### Installation d'Argo CD

Argo CD peut être installé directement dans Kubernetes via *kubectl* :

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

La commande suivante permet de contrôler que l'installation s'est déroulée correctement :

```bash
kubectl get pods -n argocd
```
Les pods doivent être en *Running* avec *Ready 1/1* (ça peut prendre quelques minutes).
---

# 🔍 Approfondissement : Qualité, Sécurité & Observabilité
## Objectifs
- **Tests** : Intégration de Pytest
- **Sécurité** : Scan des vulnérabilités Docker
- **Monitoring & Logs** : Intégration avec Prometheus

## 🛠 Prochaines étapes
À compléter...

---


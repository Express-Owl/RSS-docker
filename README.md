# Projet – Leed

## Prérequis

- cloner le dépôt
- avoir docker d’installé
- Pour plus de rapidité en faisant “docker-compose up” avoir ces images d’installés
    - mysql:latest
    - php:8.3-apache
    - curlimages/curl:latest

## Usage

Pour utiliser l’application il faut tout d’abord configurer le fichier .env :

```
AUTO_EXECUTE_CONFIG=true // configure automatiquement la base de donnée leed si à true

// les ports des services apache et mysql
APACHE_PORT=8080
MYSQL_PORT=3306

// configuration du serveur de base de donnée
MYSQL_ROOT_PASSWORD=mysql
MYSQL_DATABASE=leedDB
MYSQL_USER=leedUser
MYSQL_PASSWORD=leed
```

Il suffit ensuite de lancer

```tsx
docker-compose up -d
```

l’application leed se lance, pour savoir comment utiliser leed je vous renvoi au dépôt git de l’application https://github.com/LeedRSS/Leed
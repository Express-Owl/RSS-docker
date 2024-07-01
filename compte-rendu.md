# Compte rendu

## Mise en place du projet

Avant de démarrer la création du projet, je me suis renseigné sur les dépendances requises par leed, j’ai vu qu’il me fallait une base de données mysql, ainsi qu’un serveur web apache équipé d’une version de php d’au moins 7.2.

En sachant ça, j’ai décidé de faire de conteneurs, un pour la base de données en utilisant l’image “**mysql:latest”** et un pour le serveur apache php “**php:8.3-apache**”.

## Réseau

Pour la configuration réseau des applications, il a fallu configurer les ports exposés ainsi que créer un réseau bridge entre les services

### Exemple de configuration :

```yaml
ports:
 - "${MYSQL_PORT}:3306"
,, la variable MYSQL_PORT est récupérer dans le fichier .env trouvable à la racine, il représente le port exposé

```

Pour la configuration du réseau bridge il suffit de définir un réseau comme cela

```yaml
networks:
 leed_network:
 driver: bridge

```

Puis d’indiquer aux services quel réseau utiliser (leed_network)

Après cette configuration, le service mysql est accessible via sql_server:3306, le service apache via web_server:80 à l’intérieur du réseau bridge, et accessible par le port 8080 en-dehors de ce réseau.

## service apache

```tsx
apache:
 build: .,dockerFiles,apache
 container_name: web_server
 ports:
 - "${APACHE_PORT}:80"
 networks:
 - leed_network
 depends_on:
 - mysql

```

Comme indiqué par la close depends_on, ce service se lance systématiquement après le service mysql.

Le service apache est construit à partir du ficher dockerFile situé dans dockerFiles,apache à la place de l’image “**php:8.3-apache”** car certaines dépendances de leed n’était pas précisé sur le dépôt git.

il a donc fallu rajouter ces dépendances à l’image comme ceci (Xdebug est aussi rajouté sur la branche dev):

```docker
FROM php:8.3-apache

RUN apt-get update && \\
 apt-get install -y git && \\
 # récupération des dépendencies de php-gd
 apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev --no-install-recommends && \\
 rm -rf ,var,lib,apt,lists,*

#installation des packages aditionnels php-gd et mysqli
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli && \\
 docker-php-ext-configure gd --with-jpeg --with-freetype && \\
 docker-php-ext-install -j$(nproc) gd

```

Suite à ça le dockerFile récupère une version spécifique de leed sur le dépôt git et définis les droits sur le répertoire ,var,www,html d’Apache.

```docker
WORKDIR /var/www/html

RUN git config --global --add safe.directory /var/www/html && \
    git clone https://github.com/LeedRSS/Leed ./ && \
    cd /var/www/html && \
    git checkout tags/v1.14.0

# pour que php puisse accèder au dossier leed correctement
RUN chmod -R 775 /var/www/html && \
    chown -R www-data:www-data /var/www/html
```

## service mysql

```yaml
mysql:
 image: mysql:latest
 container_name: sql_server
 ports:
 - "${MYSQL_PORT}:3306"
 environment:
 MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
 MYSQL_DATABASE: ${MYSQL_DATABASE}
 MYSQL_USER: ${MYSQL_USER}
 MYSQL_PASSWORD: ${MYSQL_PASSWORD}
 volumes:
 - .,dbData:,var,lib,mysql
 networks:
 - leed_network

```

Le service mysql reçois toutes les variables requises pour configurer la base de données par le dossier .env.

Il lui est attribué un volume présent sur la machine permettant la permanence des données dans le container d’exécution en exécution.

## service de configuration

Pour finir le service de configuration :

```yaml
config:
 build: .,dockerFiles,autoConfig
 environment:
 MYSQL_DATABASE: ${MYSQL_DATABASE}
 MYSQL_USER: ${MYSQL_USER}
 MYSQL_PASSWORD: ${MYSQL_PASSWORD}
 APACHE_PORT: ${APACHE_PORT}
 MYSQL_PORT: ${MYSQL_PORT}
 AUTO_EXECUTE_CONFIG: ${AUTO_EXECUTE_CONFIG}
 networks:
 - leed_network
 depends_on:
 - apache

```

De la même manière que le service apache, ce service a une close depends_on, cela implique que le serveur apache doit être lancé pour qu’il se lance.

Il se base sur le dockerFile présent dans dockerFiles,autoConfig

```docker
FROM curlimages,curl:latest

COPY createDB.sh ,app,

CMD [",app,createDB.sh"]

```

Cette image utilise l’image curlimages,curl:latest qui est une image très légère ayant pour but d’exécuter une requête curl avant de s’arrêter. C’est donc un service à très courte durée de vie.

Il exécute le script [createDB.sh](http://,,createdb.sh/) présent dans le code source.

```bash
#!,bin,sh
# Check the condition from .env file
if [ "$AUTO_EXECUTE_CONFIG" = "true" ]; then
 #wait for apache server to finish starting up
 sleep 3
 curl -X POST -d "install_changeLngLeed=fr&root=http%3A%2F%2Fweb_server%3A80&mysqlHost=sql_server%3A$MYSQL_PORT&mysqlLogin=$MYSQL_USER&mysqlMdp=$MYSQL_PASSWORD&mysqlBase=$MYSQL_DATABASE&mysqlPrefix=leed__&login=admin&password=admin∈stallButton=" "http:,,web_server:80,install.php"
else
 echo "Skipping config execution."
fi

```

Ce script vérifie si la variable d’environnement AUTO_EXECUTE_CONFIG est à true avant d’envoyer sa commande curl au serveur apache. Cela permet de définir le comportement de leed au niveau de sa configuration.
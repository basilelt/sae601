
# Gitlab install doc

Ce document permet d'installer une instance gitlab de type "all in one".

Table des matières :

- [Gitlab install doc](#gitlab-install-doc)
- [Schema](#schema)
- [Prérequis](#prérequis)
  - [Certificat](#certificat)
- [Installation](#installation)
  - [Etape 1](#etape-1)
  - [Etape 2](#etape-2)
- [Configuration](#configuration)
  - [Https](#https)
  - [Registry](#registry)
  - [Docker](#docker)
    - [Etape 4](#etape-4)
  - [Ssh](#ssh)

# Schema

Les services ci dessous seront installés sur votre plateforme:

```mermaid
block-beta
  columns 6
  a["dockerd"]:2 b["gitlab/gitlab-registry"]:2 c["gitlab-runner"]:2 d["operating system"]:6
```

Ces services vont interagir entre eux comme indiqué ci dessous:

```mermaid
flowchart LR

U(user)
Re(gitlab-registry)
G(gitlab)
Ru(gitlab-runner)
D(dockerd)

U -- pull/push --> G
G -- build/test/deploy --> Ru
Ru -- executor --> D
D -- pull/push --> Re

```

# Prérequis

- Disposer d'un environnement d'exécution de 2 coeurs, 8G de mémoire et 40G de stockage
- L'environnement réseau sera configuré en mode bridge pour les VM
- Un distribution Linux disposant des [packages nécessaires](https://about.gitlab.com/install/)
- Installer [docker](https://docs.docker.com/engine/install/)
- Définir le fqdn local de votre instance ex: gitlab.basile.local et l'ajouter à votre fichier /etc/hosts
- Créer un certificat auto-signé qui sera associé à votre instance

## Certificat

L' exemple suivant permet d'obtenir un certificat auto-signé associé au FQDN gitlab.basile.local

1.Générer la clé privée gitlab.basile.local.key

```bash
openssl genpkey -out gitlab.basile.local.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
```

2.Créer le fichier gitlab.basile.local.cnf

```conf
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no
[ req_distinguished_name ]
countryName                = FR
stateOrProvinceName        = GRAND EST
localityName               = COLMAR
organizationName           = IUT
commonName                 = gitlab.basile.local
[ req_ext ]
subjectAltName = @alt_names
[alt_names]
DNS.1  = gitlab.basile.local
```

3.Générer le CSR gitlab.basile.local.csr

```bash
openssl req -new -key gitlab.basile.local.key -out gitlab.basile.local.csr -config gitlab.basile.local.cnf
```

4.Signer et générer le certificat

```bash
openssl x509 -signkey gitlab.basile.local.key -in gitlab.basile.local.csr -req -copy_extensions copyall -days 365 -out gitlab.basile.local.crt
```

# Installation

Installer **gitlab-ce** en suivant la [procédure d'installation](https://about.gitlab.com/install/) Official Linux package et en prenant en compte les informations ci dessous.

:information: L'exemple ci dessous correspond à l'installation d'une instance gitlab.basile.local sur Ubuntu

## Etape 1

Ignorer l'étape d'installation postfix.

## Etape 2

Installer le package repository **gitlab-ce**

```bash
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
```

Installer les packages en déclarant dans un premier temps l'url d'accès en http

```bash
sudo EXTERNAL_URL="http://gitlab.basile.local" apt-get install gitlab-ce
```

:check_mark_button: L'accès http://gitlab.basile.local doit être foncionnel

# Configuration

## Https

Suivre les différentes [étapes de configuration](https://docs.gitlab.com/omnibus/settings/ssl/index.html#configure-https-manually)

:information: Ignorer les étapes optionnelles

:check_mark_button: L'accès https://gitlab.basile.local doit être fonctionnel

## Registry

La registry interne Gitlab sera accessible à travers le domaine Gitlab dans notre exemple gitlab.basile.local

Suivre les différentes [étapes de configuration](https://docs.gitlab.com/ee/administration/packages/container_registry.html#configure-container-registry-under-an-existing-gitlab-domain)

:information: Uniquement les étapes 1 et 2

## Docker

Configurer le [certificat auto-signé](Certificat) en tant que root CA

```bash
sudo mkdir -p /etc/docker/certs.d/gitlab.basile.local:5050
sudo cp gitlab.basile.local.crt /etc/docker/certs.d/gitlab.basile.local:5050/ca.crt
```

Redémarrer le service docker

```bash
sudo systemctl restart docker
```

Ajouter votre utilisateur au groupe docker, cela vous permettra d'utiliser la commande docker sans sudo.

:check_mark_button: L'authentification auprès de la registry doit être foncionnel

```bash
docker login gitlab.basile.local:5050
```

### Etape 4

Avant de réaliser l'enregistrement du runner auprès de votre instance gitlab, copier le certificat auto signé de votre instance vers le dossier de configuration du service gitlab-runner.

```bash
sudo cp /etc/gitlab/ssl/gitlab.basile.local.crt /etc/gitlab-runner/certs/gitlab.basile.local.crt
```

Créer un runner au niveau de votre instance gitlab en suivant la [procédure d'installation](https://docs.gitlab.com/ee/ci/runners/runners_scope.html#create-an-instance-runner-with-a-runner-authentication-token), avec les paramètres suivants :

- gitlab url : https://gitlab.basile.local
- job tags : ```shared, docker``` et check run untagged jobs
- name : ```runner```
- executor : ```docker```
- default docker image : ```alpine:latest```

## Ssh

Afin de permettre l'utilisation de git depuis votre machine il est nécessaire :

- de [créer les clés ssh](https://docs.gitlab.com/17.7/ee/user/ssh.html#generate-an-ssh-key-pair)
- d'[intégrer la clé publique](https://docs.gitlab.com/17.7/ee/user/ssh.html#add-an-ssh-key-to-your-gitlab-account) dans votre profil utilisateur gitlab

:check_mark_button: le [test de connexion](https://docs.gitlab.com/17.7/ee/user/ssh.html#verify-that-you-can-connect) à gitlab doit être fonctionnel
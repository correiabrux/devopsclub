---
title: "ELK em 2 minutos"
date: 2017-11-09
tags: [ "Docker", "docker-compose", "Elasticsearch", "Logstash", "Kibana" ]
draft: false
---

## Resumão

Já precisou analisar logs de ELB armazenados em S3 ? Eu já !

Por isso desenrolei um `docker-compose` pra quebrar esse galho.

### Mão na massa

Instructions to run a ELK with four commands.

### Prerequisites

. Docker (https://docs.docker.com/engine/installation/linux/docker-ce/debian/) - Used to run container

. Docker Compose (https://docs.docker.com/compose/install/) - Used to provision all containers 

### Run ELK

Clone Repo

```
git clone https://bitbucket.org/correiabrux/elk.git
```

Go to the new path

```
$ cd elk/
```

Run stack

```
$ sudo docker-compose up -d
```

### Load log files

Copy files *.log to path /tmp in docker server.


### Access Kibana

Kibana (http://127.0.0.1:5601) - Exposed port 5601 

----


Bruno Correia - correiabrux@gmail.com


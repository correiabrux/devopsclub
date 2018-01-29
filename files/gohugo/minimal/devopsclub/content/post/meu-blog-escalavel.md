---
title: "Um blog versionado e escalável :)"
date: 2017-11-09
tags: [ "Terraform", "Beanstalk", "Docker", "Gohugo", "Circle-ci", "Supervisor" ]
draft: false
---

## Introdução

Primeiro devemos nos perguntar: Pra que um blog escalável ?

A resposta é simples: pra nada !!!

A ideia é só documentar um setup bacana pra qualquer aplicação, que seja versionada, escalável e que tenha um deploy contínuo de boa resiliência.

## Mão na massa

Vamos começar listando as ferramentas utilizadas pra subir esse blog:

1. Gohugo - 
Um simples gerador de páginas estáticas.
Estava procurando uma solução para um blog versionado em git e esbarrei no Gohugo.
Achei que fosse uma solução ideal pra versionamento, diferente do WordPress.
Site: http://gohugo.io/

2. Docker - 
Uma escolha pra facilitar o processo de desenvolvimento do Blog, além de ser uma boa opção para um deploy imutável.
Site: https://www.docker.com/

3. Supervisor - 
Como preciso manter 2 serviços no mesmo container (nginx e hugo-server) resolvi utilizar o supervisor pra garantir a disponibilidade desses dois serviços no container. (Me critiquem).
Site: http://supervisord.org/

4. Terraform - 
Utilizei o terraform para provisionar o Beanstalk, assim consigo subir toda a infra em qualquer nova conta da AWS.
Site: https://www.terraform.io/

5. Beanstalk - 
Uma solução de orquestração barata `de graça` com docker na AWS.
Para os leigos, isso é a minha hospedagem, onde pago somente pelos recursos que o orquestrador utiliza (load balancer e ec2(máquina virtual)).
Site: https://aws.amazon.com/pt/

6. Circle-ci - 
Poderia ser Jenkins, Travis, Rundeck ou qualquer outro, mas escolhi o circle pelo preço `de graça` para a minha demanda.
Site: https://circleci.com/

### Gohugo + Docker

Acredito que não tenha muito o que explicar sobre o Gohugo, ler a documentação dos caras é melhor do que seguir qualquer passo a passo que eu possa elaborar: http://gohugo.io/documentation/ 


Vou partilhar meu `Dockerfile` e o `docker-compose` só pra documentar o que fiz para um passo a passo de instalação da ferramenta:

- Dockerfile

```
FROM debian:latest
MAINTAINER Bruno Correia <correiabrux@gmail.com>

RUN apt-get update && \
apt-get -y install hugo nginx git supervisor && \
mkdir /home/devopsclub && \
/usr/bin/hugo new site  /home/devopsclub && \
rm /etc/nginx/sites-enabled/default && \
rm /etc/nginx/sites-available/default 

COPY nginx/gohugo /etc/nginx/sites-available/gohugo
COPY gohugo/minimal /home/devopsclub/themes/minimal
COPY gohugo/minimal/devopsclub/ /home/devopsclub/
COPY supervisor/ /etc/supervisor/conf.d/

RUN ln -s /etc/nginx/sites-available/gohugo /etc/nginx/sites-enabled/gohugo

EXPOSE 80
CMD ["/usr/bin/supervisord"]

```

- docker-compose.yml

```
version: '2'
services:

  nginx:
    build: .
    container_name: hugo
    ports:
      - "80:80/tcp"
    volumes:
      - ./gohugo/minimal/devopsclub/content/post/:/home/devopsclub/content/post
```

Resumindo: 

Segui a documentação do Gohugo, baixando o cara e fazendo o download de um tema da minha preferência.
Deixei tudo no meu repositório e faço o processo de criação da imagem docker a cada deploy.

Quando preciso subir o ambiente de desenvolvimento, só dou um `docker-compose up` e o ambiente está disponível na minha máquina local pra escrever um post novo.


### Supervisor

Como dito anteriormente, usei o supervisor pra manter 2 serviços em pé dentro do container. Vou partilhar o arquivo de configuração que está sendo copiado para `/etc/supervidor/conf.d` durante a criação da imagem docker:

- supervisord.conf

```
[supervisord]
nodaemon=true

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
user=root

[program:gohugo]
directory=/home/devopsclub
command=hugo server
user=root

```

### Terraform

Chegou a hora de preparar o ambiente que vai receber a imagem docker na AWS.
Pra deixar a stack chique, resolvi provisionar o ambiente com terraform e vou partilhar o arquivo de configuração que foi utilizado:


- terraform/devopsclub.tf

```
resource "aws_elastic_beanstalk_application" "devopsclub" {
  name        = "devopsclub"
  description = "devopscub"
}

resource "aws_elastic_beanstalk_environment" "devopsclub" {
  name                = "devopsclub"
  application         = "${aws_elastic_beanstalk_application.devopsclub.name}"
  solution_stack_name = "64bit Amazon Linux 2017.03 v2.7.4 running Multi-container Docker 17.03.1-ce (Generic)"

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "RollingUpdateEnabled"
    value = "true"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "RollingUpdateType"
    value = "Immutable"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "DeploymentPolicy"
    value = "Immutable"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name = "CrossZone"
    value = "true"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "Availability Zones"
    value = "Any 2"
  }
  
}

```

Dentro do diretório do arquivo basta rodar `terraform init`, em seguida `terraform plan` para garantir que tudo vai rodar direitinho.
Pra finalizar mandei um `terraform apply` e a mágina aconteceu.
OBS: Tudo isso com awscli instalado e devidamente configurado com uma chave que tenha as devidas permissões :) - https://aws.amazon.com/pt/cli/


### Circle ci

Com o ambiente pronto preparei o circle-ci para fazer o deploy na AWS.
Essa preparação gira em torno dos arquivos que vou partilhar abaixo, começando do `circle.yml`.

Esse arquivo nada mais é que um passo a passo para o build da minha aplicação, iniciando pela criação da imagem docker e finalizando com o envio dessa imagem para AWS.

Através do circle.ci, também estou enviando arquivos determinantes para o funcionanmento do Beanstalk, e esses arquivos ficam na S3. https://aws.amazon.com/pt/s3/


- circle.yml

```
version: 2
jobs:
  build:
    docker:
      - image: docker:17.05.0-ce-git
    steps:
      - checkout
      - setup_remote_docker    
      - run:
          name: Dependencias
          command: |
            apk add --no-cache py-pip=9.0.0-r1 zip
            pip install docker-compose==1.12.0 awscli==1.11.76
            aws configure set default.region us-west-2
            eval $(aws ecr get-login)

      - run:
          name: Build Docker
          command: docker build -t devopsclub . 

      - run:
          name: Tag Docker
          command: docker tag devopsclub:latest "490089276961.dkr.ecr.us-west-2.amazonaws.com/devopsclub:$CIRCLE_BRANCH.$CIRCLE_BUILD_NUM"

      - run:
          name: Push Docker
          command: docker push "490089276961.dkr.ecr.us-west-2.amazonaws.com/devopsclub:$CIRCLE_BRANCH.$CIRCLE_BUILD_NUM"
      
      - run:
          name: Alterando json AWS
          command: |
            sed -i'' -e "s/<IMAGE_NAME>/$CIRCLE_BRANCH/g" Dockerrun.aws.json
            sed -i'' -e "s/<TAG>/$CIRCLE_BUILD_NUM/g" Dockerrun.aws.json

      - run:
          name: Criando pacote de preferencias Beanstalk 
          command: zip devopsclub`date +%d%m%y`_$CIRCLE_BRANCH.$CIRCLE_BUILD_NUM.zip -r Dockerrun.aws.json .ebextensions/
              
      - run:
          name: Enviando configurações para S3
          command: aws s3 cp devopsclub`date +%d%m%y`_$CIRCLE_BRANCH.$CIRCLE_BUILD_NUM.zip s3://elasticbeanstalk-us-west-2-490089276961/devopsclub`date +%d%m%y`_$CIRCLE_BRANCH.$CIRCLE_BUILD_NUM.zip

      - run:
          name: Iniciando Deploy Beanstalk
          command: |
               aws elasticbeanstalk create-application-version --application-name devopsclub --version-label $CIRCLE_BRANCH.$CIRCLE_BUILD_NUM --source-bundle S3Bucket=elasticbeanstalk-us-west-2-490089276961,S3Key=devopsclub`date +%d%m%y`_$CIRCLE_BRANCH.$CIRCLE_BUILD_NUM.zip
               aws elasticbeanstalk update-environment --environment-name devopsclub --version-label $CIRCLE_BRANCH.$CIRCLE_BUILD_NUM
```

O arquivo abaixo é utilizado a cada deploy para o apontamento de detalhes como a imagem da versão atual, memória do container, porta exposta e etc... 


- Dockerrun.aws.json

```
{
	"AWSEBDockerrunVersion": "2",
	"containerDefinitions": [{
		"name": "devopsclub",
		"image": "490089276961.dkr.ecr.us-west-2.amazonaws.com/devopsclub:<IMAGE_NAME>.<TAG>",
		"essential": true,
		"Update": true,
		"memory": 512,
		"privileged": true,
		"portMappings": [{
			"hostPort": 80,
			"containerPort": 80
		}]
	}]
}

```

O arquivo a seguir já me salvou de um problemão, devo essa ao mano Wiek.

- .ebextensions/01_blockdevice-xvdcz.config

```
option_settings:
  aws:autoscaling:launchconfiguration:
    BlockDeviceMappings: /dev/xvdcz=:50:true:gp2
```

Como podem notar, o arquivo acima disponibiliza um novo dispositivo de armazenamento ao container, o que me resolveu um problema onde os discos dos containers entravam em Read Only quando atingiam 100% de uso. Por default, as instâncias provisionadas pelo Beanstalk ou ECS têm um tamanho reduzido de disco em LVM, e essa foi a maneira mais eficaz de resolver.



### Finalizando

Com a junção das tecnologias mencionadas acima, temos um ambiente completamente versionado, na aplicação e infraestrutura.
Com isso, basta fazer um commit e o deploy é iniciado automaticamente pelo circle-ci, que irá subir uma nova imagem docker para atender a versão da aplicação. 


----

Esse foi o primeiro post do DevopsClub, espero continuar documentando... Até a próxima :) 

Bruno Correia - correiabrux@gmail.com




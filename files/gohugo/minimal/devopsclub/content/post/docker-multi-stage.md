---
title: "Docker MultiStage em stack python"
date: 2018-02-01
tags: [ "Python", "Docker", "Multistage" ]
draft: false
---

## Introdução

Na tentativa de obter uma imagem docker pequena em ambientes Python, escrevi um `Dockerfile` utilizando multistage e resolvi documentar aqui.

## Mão na massa

Esse Dockerfile nada mais faz que utilizar o recurso de Multistage para descartar todo o "lixo" que possa ter ficado na imagem utilizada para build `python:2.7`.

Dei o nome de `builder` para a primeira imagem e em seguida utilizei `COPY --from` para resgatar todo o virtualenv na imagem nova, relativamente limpa.

Além disso, utilizei uma imagem `slim` do python para subir o container definitivo, isso fez com que a imagem final tivesse seu tamanho reduzido consideravelmente.


```
FROM python:2.7 AS builder
WORKDIR /home/site/

COPY files/site /home/site/

RUN virtualenv . && \
bin/pip install -r /home/site/requirements.txt

FROM python:2.7.14-slim
WORKDIR /home/site/
COPY --from=builder /home/site /home/site

ENTRYPOINT ["/home/site/bin/gunicorn", "-n", "site", "-c", \ 
            "/home/site/config/gunicorn.conf.py"]
```

## Resumão

Pra resumir, na linha `COPY files/site /home/site/` estou copiando todo o código do site, além dos requisistos que ficam em `files/site/requirements.txt`.
Em seguida instalo as dependências dentro do virtualenv `RUN virtualenv . && \` `bin/pip install -r /home/site/requirements.txt`.

Depois disso a imagem `slim` entra em ação resgatando no mesmo diretório `/home/site/` o que foi "buildado" na imagem anterior `COPY --from=builder /home/site /home/site`.

Por fim, usei um ENTRYPONT como exemplo para subir o serviço.

Até breve :)

----

Bruno Correia - correiabrux@gmail.com




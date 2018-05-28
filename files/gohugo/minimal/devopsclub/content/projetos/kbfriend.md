---
title: "KBFRIEND"
date: 2018-05-28
tags: [ "Kanboard", "Bot" ]
draft: false
---

Esse projeto tem por objetivo a integração do projeto Kanboard(https://kanboard.org/) com o Slack, onde já é possível abrir, mover e fechar cards, criar projetos, listar projetos e etc, tudo a partir de um app do slack que funciona como um CLI para Kanboard.

### GitHub
https://github.com/correiabrux/kbfriend

### Explanação

Com o uso cada vez mais frequente do Slack para alinhamento entre equipes, senti a necessidade de interagir com as tarefas do nosso board virtual(Kanboard) através do próprio Slack.

Nessa primeira etapa adicionei algumas funcionalidades que julgo importantes para evitar tarefas repetitivas no painel gráfico do kanboard.

Abaixo, o exemplo do help gerado pelo kbfriend com as funcionalidades já implementadas:

```
$kb help                                  #Lista Comandos
$kb listprojects                          #Lista Projetos
$kb listtasks project                     #Lista Taks
$kb listcolumns project                   #Lista colulnas
$kb openproject projectname               #Cria Projeto
$kb opentask project description          #Abre Task
$kb closetask taskid                      #Fecha Task
$kb movetask projectid taskid columnid    #Move Task
```

----


Bruno Correia - correiabrux@gmail.com


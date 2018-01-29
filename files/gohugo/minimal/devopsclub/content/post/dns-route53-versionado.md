---
title: "DNS Versionado Route 53"
date: 2017-11-24
tags: [ "Route53", "circle-ci", "Bitbucket" ]
draft: false
---

## Resumão

Uma das coisas em infra que dificilmente tem um versionamento aceitável é DNS.

Normalmente as configurações são feitas em painéis administrativos, como o `Route53` ou qualquer outro painel de serviços de hospedagem.

Nesse formato fica bem difícil saber o que foi alterado ao longo do tempo, além de inviabilizar um rollback numa alteração indesejada.

Foi daí que surgiu a ideia de pensar numa alternativa que documentei nesse post.

### Entendendo o Fluxo

Primeiro precisamos entender o fluxo da minha proposta de versionamento:

1 - O circle-ci(circleci.com), com a função `scheduled-workflow` inicia um container em um job agendado (cron).

2 - No container instalamos um tal de cli53, desenvolvido por `Barnaby Gray`.
https://github.com/barnybug/cli53

3 - O cli53 baixa todas as zonas do route53(Amazon) no container iniciado.

4 - O job do circle faz commit de dentro do container para um repositório no bitbucket.

### Mão na Massa

Abaixo separei cada item dessa ideia maluca pra facilitar no entendimento:

----

#### Bitbucket

Primeiro criei um repositório(de graça), criei uma ssh key na minha máquina e carreguei a chave pública.
Se não tem ideia do que to falando, temos um problema, mas vou tentar ajudar.

Pra criar a chave vai fazer algo parecido com isso aqui no seu terminal:

`ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`

Vai pedir senha, mas pra esse esquema não vai dar pra usar senha, então tecle enter em tudo até o final.

Se deu tudo certo com a criação da chave, acesse o link abaixo, substituindo `seuusuario` pelo nome do seu usuário bitbucket :)

https://bitbucket.org/account/user/seuusuario/ssh-keys/

Agora da um `Add Key` no painel e cola o conteúdo do arquivo gerado em `~/.ssh/id_rsa.pub` no campo `Key` no navegador.

----


#### Circle-Ci

1 - Beleza, agora precisamos nos logar com a credencial do bitbucket no circle-ci e carregar a chave privada gerada em `~/.ssh/id_rsa`.

Pra carregar a chave privada depois de se logar, o camihno é parecido com esse, subistituindo `seurepo` pelo nome do repositório:

https://circleci.com/bb/correiabrux/route53/edit#ssh

Agora basta clicar em `Add ssh key` e carregar o conteúdo do arquivo `~/.ssh/id_rsa` em `Private Key`.


Ahh, lembre-se de colocar `bitbucket.org` caso vá utilizar o Bitbucket mesmo.
Digo isso porque tem quem goste do `github.com` $$$, onde o host seria diferente, blz ?!


Também lembra de anotar o `fingerprint` gerado em algum lugar.


2 - Bom, nessa etapa eu tive que criar um usuário na minha conta AWS, onde dei somente leitura no `Route53` a esse usuário.
Em seguida, gerei uma key pra esse usuário na AWS e coloquei no circle:

https://circleci.com/bb/correiabrux/seurepo/edit#aws

3 - Agora você precisa dar um `Setup Project` do seu projeto lá no circle-ci e ele já vai começar a rodar um build a cada commit:

https://circleci.com/add-projects/bb/seuusuario

Atenção nesse ponto, pois o build após commit precisa ser desabilitado no final, pois nosso job faz um commit a cada build e isso faria o job entrar em um loop infinito.


4 - Agora a parte que interessa, o arquivo `circle.yml` que vai fazer toda essa mágica:


```
version: 2
jobs:
  build:

    docker:
      - image: alpine

    steps:
      - checkout
      - run:
          name: CLI 53 INSTALL
          command: |
            apk add --no-cache --update python python-dev py-pip build-base git openssh
            pip install awscli==1.11.76
            aws configure set default.region sa-east-1
            eval $(aws ecr get-login)
            pip install git+https://github.com/barnybug/cli53.git@python
       
      - add_ssh_keys:
          fingerprints:
            - "seu:fin:ger:print:que:foi:gerado"

      - run:
          name: RUN BACKUP FROM R53
          command: |
            data=`date +%d%m%Y`
            for i in `cli53 list | grep Name:| cut -d ':' -f2` ; do
              cli53 export ${i} > ${i} && echo '#' ${data} >> ${i}
            done

      - run:
          name: COMMIT BACKUP
          command: |
            ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts
            data=`date +%d%m%Y`
            echo $CIRCLE_BUILD_NUM > job
            /usr/bin/git config --global user.email "correia@layer8.com.br"
            /usr/bin/git config --global user.name "correiabrux"
            /usr/bin/git add .
            git commit -m "$data" && git push origin HEAD:master 


workflows:
  version: 2
  scheduled-workflow:
    triggers:
      - schedule:
          cron: "30 18 * * *"
          filters:
            branches:
              only: master

    jobs:
      - build
```

----


Tendo o arquivo acima, basta comitar no repositório e os builds já devem começar a acontecer, todos os dias as 18hrs e 30 min.

Pra testar você pode até mandar um `* * * * *` no cron, assim vai ver os jobs de backup acontecendo minuto a minuto.

***Lembre-se de desativar o hook que rodam os jobs a cada commit no circle, senão o job entra em loop amiguinho :)

----

#### Pra acabar

Pra finalizar, dá uma olhada no help do cli53, pois com ele é possível recriar zonas a partir dos arquivos gerados.
Isso era exatamente o que eu precisava, uma forma rápida de voltar um backup de DNS a partir de um commit determinado, que é gerado diariamente pelo circle-ci.

----

Se precisar de ajuda pra colocar isso pra funcionar, me chama que te ajudo ;)

----


Bruno Correia - correiabrux@gmail.com


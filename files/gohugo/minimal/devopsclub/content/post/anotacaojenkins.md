---
title: "Brincando de Pipeline com Jenkins + Kubernetes"
date: 2017-01-30
tags: [ "Jenkins", "Kubernetes" ]
draft: false
---

## Introdução

Na tentativa de evoluir o fluxo de deploy em um cluster kubernetes, estou documentando de alguma forma as minhas evoluções.

Durante esse post, estou no passo de escrever um pipeline que funcione dentro do jenkins, realizando o deploy dentro do cluster kubernetes. 

## Mão na massa

Basicamente coloquei um arquivo Jenkinsfile dentro do meu repositório, em seguida criei um job no Jenkins:

```
pipeline {
    agent any 

    stages {
        stage('Build') { 
            steps { 
                echo "Build..."
		sh 'sudo docker login -u ${USRDOCKERHUB} -p ${PASSDOCKERHUB}'
		sh 'sudo docker build -t devopsclub:${BUILD_NUMBER} .'
		sh 'sudo docker tag devopsclub:${BUILD_NUMBER} correiabrux/devopsclub:${BUILD_NUMBER}'
		sh 'sudo docker push correiabrux/devopsclub:${BUILD_NUMBER}'
            }
        }
        stage('Test'){
            steps {
                 echo "Test"
            }
        }
        stage('Deploy') {
            steps {
                echo "Deploy"
                sh 'kubectl set image deployment/devopsclub devopsclub=correiabrux/devopsclub:${BUILD_NUMBER}'
            }
        }
    }
}
```

----

Bruno Correia - correiabrux@gmail.com




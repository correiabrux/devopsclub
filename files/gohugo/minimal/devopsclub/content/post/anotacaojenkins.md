---
title: "Brincando de Pipeline com Jenkins + Kubernetes"
date: 2018-01-30
tags: [ "Jenkins", "Kubernetes" ]
draft: false
---

## Introdução

Na tentativa de evoluir o fluxo de deploy em um cluster kubernetes, estou documentando de alguma forma as minhas evoluções.

Durante esse post, estou no passo de escrever um pipeline que funcione dentro do jenkins, realizando o deploy para o cluster kubernetes. 

## Mão na massa

1 - Pra começar subi meu cluster kubernetes em raspberry, e por incrível que pareça, funcionou muito bem;
Dá uma olhada nesse site aqui se você quiser fazer algo parecido: `https://kubecloud.io/setup-a-kubernetes-1-9-0-raspberry-pi-cluster-on-raspbian-using-kubeadm-f8b3b85bc2d1`

2 - Vai pro gcp;
Cara, cria uma conta gratuita por lá e cria um cluster com meia dúzia de cliques :)

3 - Manifestos;
Precisei estudar um pouco pra entender como os manifestos kubernetes funcionam, mas cheguei no nível atual (iniciante), dedicando meia horinha de leitura diária por uma semana.

Segue meu manifesto:

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: devopsclub
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: devopsclub
    spec:
      containers:
        - name: devopsclub
          image: correiabrux/devopsclub:1.2 
          ports:
          - containerPort: 80
            protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: devopsclub
  labels:
    app: devopsclub
spec:
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: devopsclub
  type: LoadBalancer
```

Espero que você tenha algum conhecimento de docker pra entender o que está se passando nessa etapa rsrs.
Já tenho meu repo no dockerhub onde deixei a imagem pública, por isso não houve a necessidade de informar senhas via `imagePullSecrets`. 

4 - Jenkins;
Basicamente coloquei um arquivo Jenkinsfile dentro do meu repositório, em seguida criei um job no Jenkins.
Nesse job criei as variáveis de usuário e senha pra conseguir fazer o push da imagem nova após build, dá uma olhada:

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

Se não entendeu nada é porque não fui claro mesmo rsrs, afinal são 03 d-sw '%{http_code}'a manhã...

Façamos o seguinte, se quiser entender acesse o repo desse projeto: `https://github.com/correiabrux/devopsclub`
Além disso, fique de olho nesse post, pois pretendo documentar melhor, té mais...


----

Bruno Correia - correiabrux@gmail.com




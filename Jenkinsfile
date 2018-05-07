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
                sh 'gcloud container clusters get-credentials cluster-1 --zone us-central1-a --project myclusterk8s'
                sh 'kubectl set image -n devopsclub deployment/devopsclub devopsclub=correiabrux/devopsclub:${BUILD_NUMBER}'
            }
        }
    }
}

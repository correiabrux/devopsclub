pipeline {
    agent any 

    stages {
        stage('Build') { 
            steps { 
                echo "Buld..."
		            docker login -u ${USRDOCKERHUB} -p ${PASSDOCKERHUB}
		            docker build -t devopsclub:${BUILD_NUMBER}
		            docker tag devopsclub correiabrux/devopsclub:${BUILD_NUMBER}
		            docker push correiabrux/devopsclub:${BUILD_NUMBER}
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
            }
        }
    }
}

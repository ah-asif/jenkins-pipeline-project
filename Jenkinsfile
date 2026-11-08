pipeline {

    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = 'go-api'
        IMAGE_NAME = 'go-api'
        APP_PORT = '9090'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning GitHub Repository...'

                git branch: 'main',
                    credentialsId: '91b54de1-3220-4d55-965e-e31b50343092',
                    url: 'https://github.com/ah-asif/ah-private-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Go Docker Image...'

                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                        -t ${IMAGE_NAME}:latest \
                        .
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                echo 'Deploying Go Application...'

                sh '''
                    docker rm -f ${APP_NAME} || true

                    docker run -d \
                        --name ${APP_NAME} \
                        --restart unless-stopped \
                        -e PORT=${APP_PORT} \
                        -p ${APP_PORT}:${APP_PORT} \
                        ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Checking Application Health...'

                sh '''
                    for i in $(seq 1 15); do

                        if curl -fsS http://localhost:${APP_PORT}/health; then
                            echo ""
                            echo "Application is Healthy!"
                            exit 0
                        fi

                        echo "Waiting for application... ($i/15)"
                        sleep 2

                    done

                    echo "Health Check Failed!"
                    docker logs ${APP_NAME}
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo '================================'
            echo 'DEPLOYMENT SUCCESSFUL!'
            echo '================================'
            echo 'Application: http://localhost:9090'
            echo 'Health: http://localhost:9090/health'
        }

        failure {
            echo 'Pipeline Failed!'
            echo 'Please check the Console Output.'
        }
    }
}


pipeline {

    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME   = 'go-api'
        IMAGE_NAME = 'go-api'
        APP_PORT   = '9090'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Building branch: ${env.BRANCH_NAME}"
                checkout scm
            }
        }

        stage('Prepare Image Tag') {
            steps {
                script {
                    env.IMAGE_TAG = env.BUILD_TAG
                        .toLowerCase()
                        .replaceAll(/[^a-z0-9_.-]/, '-')
                }

                echo "Image tag: ${IMAGE_TAG}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Go Docker Image...'

                sh '''
                    set -e

                    docker build \
                        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
                        .
                '''
            }
        }

        stage('Deploy Container') {
            when {
                branch 'main'
            }

            steps {
                echo 'Deploying Go Application...'

                sh '''
                    set -eu

                    if docker container inspect "$APP_NAME" >/dev/null 2>&1; then

                        echo "Removing existing container..."

                        docker rm -f "$APP_NAME" || true

                        REMOVED=false

                        for i in $(seq 1 30); do
                            if ! docker container inspect "$APP_NAME" >/dev/null 2>&1; then
                                REMOVED=true
                                break
                            fi

                            echo "Waiting for container removal... ($i/30)"
                            sleep 1
                        done

                        if [ "$REMOVED" != "true" ]; then
                            echo "ERROR: Container removal timed out!"
                            exit 1
                        fi
                    fi

                    docker run -d \
                        --name "$APP_NAME" \
                        --restart unless-stopped \
                        -e PORT="$APP_PORT" \
                        -p "$APP_PORT:$APP_PORT" \
                        "$IMAGE_NAME:$IMAGE_TAG"
                '''
            }
        }

        stage('Verify Deployment') {
            when {
                branch 'main'
            }

            steps {
                echo 'Checking Application Health...'

                sh '''
                    set -e

                    for i in $(seq 1 15); do

                        if curl -fsS "http://localhost:${APP_PORT}/health"; then
                            echo ""
                            echo "Application is Healthy!"
                            exit 0
                        fi

                        echo "Waiting for application... ($i/15)"
                        sleep 2

                    done

                    echo "Health Check Failed!"
                    docker logs "$APP_NAME"
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo '================================'
            echo 'PIPELINE SUCCESSFUL!'
            echo '================================'
        }

        failure {
            echo 'Pipeline Failed!'
            echo 'Please check Console Output.'
        }

        always {
            echo 'Cleaning Jenkins Workspace...'
            cleanWs()
            echo 'Workspace Cleanup Completed!'
        }
    }
}


pipeline {

    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME  = 'go-api'
        IMAGE_NAME = 'go-api'
        APP_PORT  = '9090'
    }

    stages {

        // 1. CHECKOUT
        stage('Checkout') {
            steps {
                echo "Building branch: ${env.BRANCH_NAME}"
                checkout scm
            }
        }

        // 2. PREPARE IMAGE TAG
        stage('Prepare Image Tag') {
            steps {
                script {
                    env.IMAGE_TAG = ("${env.BUILD_NUMBER}-${env.BRANCH_NAME}")
                        .toLowerCase()
                        .replaceAll(/[^a-z0-9_.-]/, '-')
                }

                echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // 3. BUILD DOCKER IMAGE
        stage('Build Docker Image') {
            steps {
                echo 'Building Go API Docker Image...'

                sh '''
                    set -e

                    docker build \
                        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
                        .
                '''
            }
        }

        // 4. DEPLOY CONTAINER (MAIN ONLY)
        stage('Deploy Container') {

            when {
                branch 'main'
            }

            steps {
                echo 'Deploying Go Application...'

                sh '''
                    set -eu

                    # Remove existing container
                    if docker container inspect "$APP_NAME" >/dev/null 2>&1; then

                        echo "Removing existing container..."

                        docker rm -f "$APP_NAME" || true

                        REMOVED=false

                        for i in $(seq 1 30); do

                            if ! docker container inspect "$APP_NAME" >/dev/null 2>&1; then
                                REMOVED=true
                                break
                            fi

                            echo "Waiting for removal... ($i/30)"
                            sleep 1

                        done

                        if [ "$REMOVED" != "true" ]; then
                            echo "Container removal timed out!"
                            exit 1
                        fi
                    fi

                    # Deploy locally built image
                    docker run -d \
                        --name "$APP_NAME" \
                        --restart unless-stopped \
                        -e PORT="$APP_PORT" \
                        -p "$APP_PORT:$APP_PORT" \
                        "${IMAGE_NAME}:${IMAGE_TAG}"

                    echo "Container deployed successfully!"
                '''
            }
        }

        // 5. VERIFY DEPLOYMENT
        stage('Verify Deployment') {

            when {
                branch 'main'
            }

            steps {
                echo 'Checking Application Health...'

                sh '''
                    set -e

                    for i in $(seq 1 15); do

                        if curl -fsS \
                            "http://localhost:${APP_PORT}/health"; then

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

        // 6. ARCHIVE DEPLOYMENT INFORMATION
        stage('Archive Deployment Info') {

            when {
                branch 'main'
            }

            steps {
                echo 'Generating Deployment Metadata...'

                sh '''
                    cat > "deploy-info-${BUILD_NUMBER}.txt" <<EOF
Build: ${BUILD_NUMBER}
Image: ${IMAGE_NAME}:${IMAGE_TAG}
Commit: $(git rev-parse HEAD)
Branch: ${BRANCH_NAME}
Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
URL: ${BUILD_URL}
EOF
                '''

                archiveArtifacts(
                    artifacts: "deploy-info-${BUILD_NUMBER}.txt",
                    fingerprint: true,
                    followSymlinks: false
                )
            }
        }
    }

    // 7. POST BUILD ACTIONS
    post {

        success {
            echo '================================'
            echo 'PIPELINE SUCCESSFUL!'
            echo '================================'

            script {
                if (env.BRANCH_NAME == 'main') {
                    echo "Application: http://localhost:${APP_PORT}"
                    echo "Health: http://localhost:${APP_PORT}/health"
                } else {
                    echo "Branch/PR build successful."
                    echo "No deployment performed."
                }
            }
        }

        failure {
            echo 'PIPELINE FAILED!'
            echo 'Check Jenkins Console Output.'
        }

        always {
            echo "Build ${env.BUILD_NUMBER} finished."

            echo 'Cleaning Jenkins Workspace...'
            cleanWs()
            echo 'Workspace Cleanup Completed!'
        }
    }
}

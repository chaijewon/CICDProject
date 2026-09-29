pipeline {

    agent any

    environment {

        IMAGE_NAME = "local-spring-app"

        BLUE_CONTAINER = "spring-blue"

        GREEN_CONTAINER = "spring-green"

        NGINX_CONF = "/home/ubuntu/app/nginx.conf"

    }


    stages {

        // =================================================
        // 1. Git Checkout
        // =================================================

        stage('Checkout') {

            steps {

                checkout scm

            }
        }

        
        // =================================================
        // 2. Spring Boot Build
        // =================================================

        stage('Build') {

            steps {

                sh '''
                    chmod +x gradlew

                    ./gradlew clean build -x test
                '''

            }
        }


        // =================================================
        // 3. Docker Image Build
        // =================================================

        stage('Docker Build') {

            steps {

                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:latest \
                        .
                '''

            }
        }

        
        // =================================================
        // 4. 현재 Blue / Green 확인
        // =================================================

        stage('Check Current Color') {

            steps {

                script {

                    def active = sh(
                        script: '''
                            grep -o "127.0.0.1:[0-9]*" \
                            /home/ubuntu/app/nginx.conf \
                            | head -1
                        ''',
                        returnStdout: true
                    ).trim()


                    if (active.contains("8081")) {

                        env.CURRENT_COLOR = "blue"
                        env.NEW_COLOR = "green"
                        env.NEW_PORT = "8082"

                    } else {

                        env.CURRENT_COLOR = "green"
                        env.NEW_COLOR = "blue"
                        env.NEW_PORT = "8081"

                    }


                    echo "현재 서비스 : ${env.CURRENT_COLOR}"
                    echo "새 서비스   : ${env.NEW_COLOR}"
                    echo "새 포트     : ${env.NEW_PORT}"
                }
            }
        }


        // =================================================
        // 5. 새로운 서버 실행
        // =================================================

        stage('Start New Server') {

            steps {

                sh '''
                    docker compose up -d ${NEW_COLOR}
                '''
            }
        }


        // =================================================
        // 6. Health Check
        // =================================================

        stage('Health Check') {

            steps {

                sh '''
                    echo "Waiting for ${NEW_COLOR}..."

                    for i in {1..30}
                    do

                        if curl -f http://localhost:${NEW_PORT}/actuator/health
                        then

                            echo "================================"
                            echo "NEW SERVER IS HEALTHY"
                            echo "================================"

                            exit 0

                        fi

                        echo "Waiting..."

                        sleep 3

                    done


                    echo "Health Check Failed"

                    exit 1
                '''
            }
        }


        // =================================================
        // 7. Nginx 전환
        // =================================================

        stage('Switch Nginx') {

            steps {

                sh '''
                    echo "Switching Nginx..."

                    if [ "${NEW_COLOR}" = "blue" ]
                    then

                        sed -i \
                        's/127.0.0.1:8082/127.0.0.1:8081/' \
                        ${NGINX_CONF}

                    else

                        sed -i \
                        's/127.0.0.1:8081/127.0.0.1:8082/' \
                        ${NGINX_CONF}

                    fi


                    nginx -t

                    nginx -s reload

                    echo "Nginx switched to ${NEW_COLOR}"
                '''
            }
        }


        // =================================================
        // 8. 기존 서버 종료
        // =================================================

        stage('Stop Old Server') {

            steps {

                sh '''
                    sleep 5

                    docker compose stop ${CURRENT_COLOR}

                    echo "Old server stopped : ${CURRENT_COLOR}"
                '''
            }
        }

    }


    post {

        success {

            echo "======================================"
            echo " BLUE/GREEN DEPLOY SUCCESS"
            echo " CURRENT : ${NEW_COLOR}"
            echo " PORT    : ${NEW_PORT}"
            echo "======================================"
        }


        failure {

            echo "======================================"
            echo " DEPLOY FAILED"
            echo " OLD SERVER IS STILL RUNNING"
            echo "======================================"
        }

    }
}
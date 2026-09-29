pipeline {

    agent any

    environment {

        IMAGE_NAME = "local-spring-app"

        BLUE_CONTAINER = "spring-blue"

        GREEN_CONTAINER = "spring-green"

        NGINX_CONF = "/home/sist/app/nginx.conf"

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
                            /home/sist/app/nginx.conf \
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

        // =================================================
        // 6. Health Check
        // =================================================

        // =================================================
        // 6. Health Check
        // =================================================

        stage('Health Check') {

            steps {

                script {
                    // NEW_COLOR 값("green" 또는 "blue")에 따라 실제 컨테이너 이름 매핑
                    def targetContainer = (env.NEW_COLOR == "green") ? env.GREEN_CONTAINER : env.BLUE_CONTAINER
                    env.TARGET_CONTAINER = targetContainer
                }

                sh '''
                    echo "Waiting for ${NEW_COLOR} (${TARGET_CONTAINER}) on port ${NEW_PORT}..."

                    HEALTHY=false

                    # seq를 사용하여 1부터 30까지 안정적으로 반복
                    for i in $(seq 1 30)
                    do
                        if curl -s -f http://localhost:${NEW_PORT}/actuator/health > /dev/null 2>&1
                        then
                            echo "================================"
                            echo "NEW SERVER IS HEALTHY"
                            echo "================================"
                            HEALTHY=true
                            break
                        fi

                        echo "Attempt $i/30: Waiting for application to start..."
                        sleep 3
                    done

                    if [ "$HEALTHY" = "false" ]; then
                        echo "Health Check Failed. Printing container logs for debugging:"
                        docker logs --tail 50 ${TARGET_CONTAINER} || true
                        exit 1
                    fi
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

                    # 1. 깃 워크스페이스에 있는 nginx.conf 파일 수정
                    if [ "${NEW_COLOR}" = "blue" ]
                    then
                        sed -i 's/127.0.0.1:8082/127.0.0.1:8081/' nginx.conf
                    else
                        sed -i 's/127.0.0.1:8081/127.0.0.1:8082/' nginx.conf
                    fi

                    # 2. 수정된 파일을 실제 Nginx 설정 경로로 복사
                    sudo cp nginx.conf /home/sist/app/nginx.conf

                    # 3. Nginx 문법 검사 후 systemctl로 서비스 재시작
                    sudo nginx -t
                    sudo systemctl restart nginx

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
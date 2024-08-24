pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/joshlopez07/demo-devops-java.git'
        BRANCH = 'master'
        GITHUB_CREDENTIALS = 'github_credentials'
        OWASP_REPORT_PATH = 'owasp-report.html'
        SONAR_PROJECT_KEY = 'joshlopez07_demo-devops-java-devsu'
        SONAR_ORG = 'Joseph López'
        DOCKER_IMAGE = "joshlopez07/demo-devops-java:1.0.0" // Repositorio en Docker Hub
        DOCKERHUB_CREDENTIALS = 'dockerhub_credentials' 
        MINIKUBE_IP = '54.89.184.74' //Ip instancia EC2
        KUBECONFIG = '/home/jenkins/.kube/config' 
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: "${BRANCH}", url: "${GIT_REPO}", credentialsId: "${GITHUB_CREDENTIALS}"
            }
        }
        
        stage('Build and Test') {
            steps {
                sh 'mvn clean package'
            }
        }

        /*stage('Test OWASP') {
            steps {
                sh 'mvn org.owasp:dependency-check-maven:check'
                publishHTML([reportName: 'OWASP Dependency Check', reportDir: '.', reportFiles: "${OWASP_REPORT_PATH}"])
            }
        }*/

        stage('Test OWASP Dependency-Check Vulnerabilities') {
            steps {
                dependencyCheck additionalArguments: ''' 
                    -o './'
                    -s './'
                    -f 'ALL' 
                    --prettyPrint''', odcInstallation: 'OWASP Dependency-Check Vulnerabilities'
        
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('Test Code Review') {
            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh "mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY}"
                    //mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=joshlopez07_demo-devops-java-devsu
                    //sh "mvn sonar:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY} -Dsonar.organization=${SONAR_ORG} -Dsonar.login=${SONAR_TOKEN}"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t demo-devops-java:1.0.0 .'
                    sh "docker tag demo-devops-java:1.0.0 ${DOCKER_IMAGE}"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh 'echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin'
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
        
        stage('Deploy to Minikube') {
            steps {
                script {
                    sh "kubectl apply -f deployment.yaml --kubeconfig=${KUBECONFIG}"
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
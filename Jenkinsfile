pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/joshlopez07/demo-devops-java.git'
        BRANCH = 'master'
        GITHUB_CREDENTIALS = 'github_credentials'
        DOCKER_IMAGE = "demo-devops-java:1.0.0"
        OWASP_REPORT_PATH = 'owasp-report.html'
        SONAR_PROJECT_KEY = 'joshlopez07_demo-devops-java-devsu'
        SONAR_ORG = 'Joseph López'
        //SONAR_TOKEN = 'your-sonarcloud-token'
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

        stage('OWASP Dependency-Check Vulnerabilities') {
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
        
        stage('Deploy') {
            steps {
                script {
                    sh 'eval $(minikube -p minikube docker-env)'
                    sh "docker build -t ${DOCKER_IMAGE} ."
                    sh "kubectl apply -f k8s/deployment.yaml --kubeconfig=${KUBECONFIG}"
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
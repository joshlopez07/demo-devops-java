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
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
        MINIKUBE_IP = '54.89.184.74' //Ip instancia EC2
        KUBECONFIG = '/home/jenkins/.kube/config'
        NVD_API_KEY = 'c04ad272-f369-4fc3-9171-820a44bfb756'
        JMETER_HOME = '/opt/jmeter'  // Ruta donde está instalado JMeter
        JMETER_JMX = 'demo-devops-java.jmx'                // Nombre del archivo .jmx
        RESULTS_DIR = 'jmeter_results'                     // Carpeta para almacenar resultados de JMeter
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: "${BRANCH}", url: "${GIT_REPO}", credentialsId: "${GITHUB_CREDENTIALS}"
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests' // Construir el proyecto sin ejecutar las pruebas
            }
        }

        stage('Unit  Tests') {
            steps {
                sh 'mvn clean test' // Ejecutar solo las pruebas
            }
        }

        stage('Test  OWASP') {
            steps {
                sh "ls -la"
                sh 'mvn org.owasp:dependency-check-maven:check -Dnvd.api.key=${NVD_API_KEY}'
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
                    sh 'mvn clean verify org.jacoco:jacoco-maven-plugin:report org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY}'
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

        stage('Scan Docker Image with Trivy') {
            steps {
                script {
                    //Si se quiere detener el pipeline por las vulnerabilidades encontradas use el siguiente comando
                    //sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity HIGH,CRITICAL --no-progress --exit-code 1 ${DOCKER_IMAGE}"
                    
                    //Si se quiere continuar el pipeline omitiendo las vulnerabilidades encontradas use el siguiente comando
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity HIGH,CRITICAL --no-progress --exit-code 0 ${DOCKER_IMAGE}"
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

        stage('JMeter Test') {
            steps {
                script {
                    // Crear directorio para resultados
                    sh "mkdir -p ${RESULTS_DIR}"

                    // Ejecutar pruebas de JMeter en modo non-GUI (headless)
                    sh "${JMETER_HOME}/bin/jmeter -n -t ${JMETER_JMX} -l ${RESULTS_DIR}/results.jtl -e -o ${RESULTS_DIR}/report"
                }
            }
        }

        stage('Publish JMeter Report') {
            steps {
                script {
                    // Publicar el reporte HTML de JMeter
                    publishHTML([
                        reportDir: "${RESULTS_DIR}/report",
                        reportFiles: 'index.html',
                        reportName: 'JMeter Test Report'
                    ])
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
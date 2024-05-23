pipeline {
    agent any
        tools{
            jdk 'openjdk17'
            maven 'maven3'
        }
        environment{
            SCANNER_HOME= tool 'sonar-scanner'
        }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', changelog: false, credentialsId: 'git_Credentials_With_Token', poll: false, url: 'https://github.com/s371102/DevOps_001_Project.git'
            }
        }
        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }
        stage('Test') {
            steps {
                sh "mvn test"
            }
        }
        stage('File system scan') {
            steps {
                sh "trivy fs --format table -o trivy-image-report.html ."
            }
        }
        stage('Sonarqube - analysis') {
            steps {
                sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=BoardGame -Dsonar.projectkey=Boardgame \
                -Dsonar.java.binaries=. '''
            }
        }
        stage('Quality Gate') {
            steps {
                script{
                    waitForQualityGate abortPipeline: false, credentialId: 'sonar-password'
                }
            }
        }
        stage('Build') {
            steps {
                sh "mvn package"
            }
        }
        stage('Publish artifacts - Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'global-settings', jdk: 'openjdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh "mvn deploy"
                }
            }
        }
        stage('Build & Tag Docker image') {
            steps {
                script{
                    withDockerRegistry(credentialsId: 'docker-credentials', toolName: 'docker') {
                        sh "docker build -t akashray3/devops001:latest ."
                        
                    }
                }
            }
        }
        stage('Docker Image scan') {
            steps {
                sh "trivy image --formart table -o trivy-fs-report.html akashray3/devops001:latest "
            }
        }
        stage('Push Docker image') {
            steps {
                script{
                    withDockerRegistry(credentialsId: 'docker-credentials', toolName: 'docker') {
                        sh "docker push -t akashray3/devops001:latest ."
                        
                    }
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'kubernetes', contextName: '', credentialsId: 'k8-cred', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'https://10.196.36.214:6443') {
                    sh "kubectl apply -f deployment-service.yaml"
                }
            }
        }
        stage('Verify K8s deployment') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'kubernetes', contextName: '', credentialsId: 'k8-cred', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'https://10.196.36.214:6443') {
                    sh "kubectl get pods -n webapps"
                    sh "kubectl get svc -n webapps"
                }
            }
        }
    }
}

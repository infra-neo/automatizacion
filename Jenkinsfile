pipeline {
    agent any
    environment {
        // Cargar variables desde archivo seguro
        CONFIG = credentials('config_env_secret')
    }
    stages {
        stage('Preparar entorno') {
            steps {
                sh 'chmod +x automation/run_automation.sh'
            }
        }
        stage('Ejecutar automatización') {
            steps {
                withCredentials([file(credentialsId: 'config_env_secret', variable: 'CONFIG_FILE')]) {
                    sh 'source $CONFIG_FILE && ./automation/run_automation.sh'
                }
            }
        }
        stage('Guardar artefactos') {
            steps {
                archiveArtifacts artifacts: 'output/**', allowEmptyArchive: true
            }
        }
    }
    post {
        always {
            echo 'Pipeline finalizado.'
        }
    }
}

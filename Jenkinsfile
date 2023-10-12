pipeline {
    agent { node { label 'agent-1' } }
    // global access
    environment{
        packageVersion = ''
    }
    stages {
        stage('Deploy') {
            steps {
                echo "Deployment"
            }
        }
    }

    post{
        always{
            echo 'cleaning up workspace'
            deleteDir()
        }
    }
}
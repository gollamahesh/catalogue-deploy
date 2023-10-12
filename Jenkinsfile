pipeline {
    agent { node { label 'agent-1' } }
    // global access
    environment{
        packageVersion = ''
    }
    stages {
        // this job will wait until downstream job is over
        stage('Deploy') {
            steps {
                echo "Deployment"
                build job: "../catalogue-deploy", wait:true
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
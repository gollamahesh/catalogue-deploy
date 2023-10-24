pipeline {
    agent { node { label 'AGENT-1' } }
    parameters{
        string(name: 'version', defaultValue: '1.0.1', description: 'which verion to deploy')
    }
    // // global access
    // environment{
    //     packageVersion = ''
    // }
    stages {
        // this job will wait until downstream job is over
        stage('Deploy') {
            steps {
                echo "deploying"
                echo "version from parameters: ${params.version}"
                
                
            }
        }
        stage('init') {
            steps {
                sh """
                    cd terraform
                    terraform init -reconfigure
                """   
            }
        }
        stage('plan') {
            steps {
                sh """
                    cd terraform
                    terraform plan -var="appversion=${params.version}"
                """   
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
pipeline {
  agent any

  stages {
    stage ('Checkout') {
      steps {
        git branch: 'master',
        credentialsId: 'github',
        url: 'https://github.com/deveshchanchlani/infrastructure-as-code-sample-lab.git'
      }
    }

    stage('create AMI') {
      agent {
        docker {
          image 'hashicorp/packer:light'
          args '--mount type=bind,source=${workspace}/packer,target=/mnt/packer'
        }
      }
      steps {
        sh 'packer build /mnt/packer/baseAMI.json'
      }
    }
  }
}

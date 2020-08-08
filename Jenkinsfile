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

    // stage('Initialize') {
    //     dockerHome = tool 'myDocker'
    //     env.PATH = "${dockerHome}/bin:${env.PATH}"
    // }

    stage('create AMI') {
      agent {
        docker {
          image 'hashicorp/packer:light'
          args '--mount type=bind,source=${workspace}/infrastructure-as-code-sample-lab/packer/baseAMI.json,target=/mnt/baseAMI.json'
        }
      }
      steps {
        packer build /mnt/baseAMI.json
      }
    }
  }
}

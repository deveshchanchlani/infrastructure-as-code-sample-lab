pipeline {
  agent {
    docker {
      image 'hashicorp/packer:light'
    }
  }
  stages {
    stage ('Checkout') {
      steps {
        git branch: 'master',
        credentialsId: 'github',
        url: 'https://github.com/deveshchanchlani/infrastructure-as-code-sample-lab.git'
      }
    }

    stage('Initialize') {
        def dockerHome = tool 'myDocker'
        env.PATH = "${dockerHome}/bin:${env.PATH}"
    }

    stage('create AMI') {
      steps {
        sh '''docker run -it --mount type=bind,source=./packer/baseAMI.json,target=/mnt/baseAMI.json
    hashicorp/packer:latest build /mnt/baseAMI.json'''
      }
    }
  }
}

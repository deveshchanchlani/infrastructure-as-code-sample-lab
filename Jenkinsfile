pipeline {
  agent {
    docker {
      image 'hashicorp/packer:light'
    }

  }
  stages {
    stage('create AMI') {
      steps {
        sh '''docker run -it --mount type=bind,source=baseAMI.json,target=baseAMI.json
    hashicorp/packer:latest build baseAMI.json'''
      }
    }

  }
}
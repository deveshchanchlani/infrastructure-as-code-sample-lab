pipeline {
  agent {
    docker {
      image 'hashicorp/packer:light'
    }

  }
  stages {
    stage('create AMI') {
      steps {
        sh '''docker run -it --mount type=bind,source=./packer/baseAMI.json,target=/mnt/baseAMI.json
    hashicorp/packer:latest build /mnt/baseAMI.json'''
      }
    }

  }
}

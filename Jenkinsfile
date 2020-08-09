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

    // stage('Create AMI') {
    //   agent {
    //     docker {
    //       image 'hashicorp/packer:light'
    //       args "--mount type=bind,source=${workspace}/packer,target=/mnt/packer --entrypoint=\'\'"
    //     }
    //   }
    //   steps {
    //     withCredentials([
    //         usernamePassword(
    //           credentialsId: '15fab667-1a8d-48c1-8f18-08761a6ef87d',
    //           passwordVariable: 'AWS_SECRET',
    //           usernameVariable: 'AWS_KEY')
    //       ]) {
    //         sh "packer build -var aws_access_key=${AWS_KEY} -var aws_secret_key=${AWS_SECRET} /mnt/packer/baseAMI.json"
    //       }
    //   }
    // }

    // stage('Terraform Init') {
    //   agent {
    //     docker {
    //       image 'hashicorp/terraform:light'
    //       args "--entrypoint=\'\'"
    //     }
    //   }
    //   steps {
    //     sh 'cd terraform'
    //     sh 'terraform init'
    //   }
    // }

    stage('Terraform Apply') {
      agent {
        docker {
          image 'hashicorp/terraform:light'
          args "--entrypoint=\'\'"
        }
      }
      steps {
        withCredentials([
            usernamePassword(
              credentialsId: '15fab667-1a8d-48c1-8f18-08761a6ef87d',
              passwordVariable: 'AWS_SECRET',
              usernameVariable: 'AWS_KEY')
          ]) {
            sh 'cd terraform'
            sh 'terraform init'
            sh "terraform apply -auto-approve -var aws_access_key=${AWS_KEY} -var aws_secret_key=${AWS_SECRET}"
          }
      }
    }
  }
}

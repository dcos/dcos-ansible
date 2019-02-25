@Library('sec_ci_libs@v2-latest') _

def master_branches = ["master", ] as String[]

pipeline {
  agent none
  environment {
    IMAGE = "dcos-ansible-bundle"

    // Get credentials for publishing to Docker hub.
    DOCKER = credentials('docker-hub-credentials')
  }

  stages {
    stage("Verify author") {
      agent {
        label "mesos"
      }
      user_is_authorized(master_branches, '8b793652-f26a-422f-a9ba-0d1e47eb9d89', '#sre')
    }

    stage('lint') {
      agent {
        label "py36"
      }
      // Requires more recent Pipeline plugin
      // options {
      //   retry(3)
      //   timeout(time: 5, unit: 'MINUTES')
      // }
      steps {
        sh("pip install ansible-lint==4.0.1 yamllint==1.11.1")
        sh("yamllint -c .yamllint.yml .")
        sh("ansible-lint roles/")
      }
    }

    stage('molecule test') {
      parallel {
        stage('molecule test (ec2_centos7)') {
          agent {
            label "py36"
          }
          // try {
            // Requires more recent Pipeline plugin
            // options {
            //   retry(3)
            //   timeout(time: 60, unit: 'MINUTES')
            // }

            steps {
              sh("pip install -r test_requirements.txt")
              sh("cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml")
              // withAWS(credentials:'arn:aws:iam::850970822230:user/jenkins') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                sh("molecule test --scenario-name ec2_centos7")
              }
            }
          // } finally {
          //    sh("molecule destroy --scenario-name ec2_centos7")
          // }
        }
        stage('molecule test (ec2_rhel7)') {
          agent {
            label "py36"
          }
          // try {
            // Requires more recent Pipeline plugin
            // options {
            //   retry(3)
            //   timeout(time: 60, unit: 'MINUTES')
            // }

            steps {
              sh("pip install -r test_requirements.txt")
              sh("cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml")
              // withAWS(credentials:'arn:aws:iam::850970822230:user/jenkins') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                sh("molecule test --scenario-name ec2_rhel7")
              }
            }
          // } finally {
          //    sh("molecule destroy --scenario-name ec2_rhel7")
          // }
        }
      }
    }

    stage('docker bundle build and publish') {
      agent {
        label "mesos"
      }
      // Requires more recent Pipeline plugin
      // options {
      //   retry(3)
      //   timeout(time: 15, unit: 'MINUTES')
      // }
      steps {
        // Login to the Docker registry.
        sh("docker login -u ${DOCKER_USR} -p ${DOCKER_PSW}")
        sh("docker build -t mesosphere/${IMAGE}:latest .")
        script {
          // Calculate Docker image tag based on commit id.
          env.dockerTag = sh(script: "echo \$(git rev-parse --abbrev-ref HEAD)-\$(git rev-parse --short HEAD)", returnStdout: true).trim()

          // Tag and push the image we built earlier.
          sh("docker tag mesosphere/${IMAGE}:latest mesosphere/${IMAGE}:${env.dockerTag}")
          sh("docker push mesosphere/${IMAGE}:${env.dockerTag}")
          sh("docker push mesosphere/${IMAGE}:latest")
        }
      }
    }
  }
}

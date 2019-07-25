@Library('sec_ci_libs@v2-latest') _

def master_branches = ["master", ] as String[]

pipeline {
  agent none
  environment {
    IMAGE = "dcos-ansible-bundle"

    // Get credentials for publishing to Docker hub.
    DOCKER = credentials('docker-hub-credentials')
  }
  options {
    disableConcurrentBuilds()
  }

  stages {
    stage("Verify author") {
      agent {
        label "mesos"
      }
      steps {
        user_is_authorized(master_branches, '8b793652-f26a-422f-a9ba-0d1e47eb9d89', '#sre')
      }
    }

    stage('lint') {
      agent {
        label "py36"
      }
      steps {
        retry(3) {
          sh("pip install -r test_requirements.txt")
        }
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
          steps {
            retry(3) {
              sh("pip install -r test_requirements.txt")
            }
            sh("cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml")
            // withAWS(credentials:'arn:aws:iam::850970822230:user/jenkins') {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
              ]) {
              retry(3) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh("molecule test --scenario-name ec2_centos7")
                }
              }
            }
          }
        }
        stage('molecule test (ec2_rhel7)') {
          agent {
            label "py36"
          }
          steps {
            retry(3) {
              sh("pip install -r test_requirements.txt")
            }
            sh("cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml")
            // withAWS(credentials:'arn:aws:iam::850970822230:user/jenkins') {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
              ]) {
              retry(3) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh("molecule test --scenario-name ec2_rhel7")
                }
              }
            }
          }
        }
      }
    }

    stage('publish') {
      parallel {
        stage('galaxy.ansible.com') {
          when {
            branch 'master'
          }
          agent {
            label "py36"
          }
          steps {
            sh("mazer build")
            // sh("mazer publish --api-key=${GALAXY_API_KEY} ./releases")
          }
        }
        stage('hub.docker.com') {
          when {
            branch 'master'
          }
          agent {
            label "mesos"
          }
          steps {
            // Login to the Docker registry.
            retry(3) {
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
    }
  }
}

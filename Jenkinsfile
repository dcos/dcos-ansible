@Library('sec_ci_libs@v2-latest') _

def master_branches = ["master", ] as String[]

pipeline {
  agent none
  environment {
    IMAGE = "dcos-ansible-bundle"
    DOCKER = credentials('docker-hub-credentials')
  }
  options {
    disableConcurrentBuilds()
  }

  stages {
    stage("Verify author for PR") {
      agent {
        label "py36"
      }
      when {
        beforeAgent true
        changeRequest()
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
        ansiColor('xterm') {
          script {
            env.LINUX_DOUBLE_SPOT_PRICE = sh (returnStdout: true, script: "#!/usr/bin/env sh\nset +o errexit\ncurl --silent --location http://spot-price.s3.amazonaws.com/spot.js | sed -e 's/callback(//' -e 's/);//'| jq -r '.config.regions[] | select(.region == \"us-east\") | .instanceTypes[].sizes[] | select(.size == \"m5.xlarge\") | .valueColumns[] | select(.name == \"linux\") | (.prices.USD | tonumber | . * 2)' 2>/dev/null || echo ''").trim()
            env.RHEL_TRIPLE_LINUX_SPOT_PRICE = sh (returnStdout: true, script: "#!/usr/bin/env sh\nset +o errexit\ncurl --silent --location http://spot-price.s3.amazonaws.com/spot.js | sed -e 's/callback(//' -e 's/);//'| jq -r '.config.regions[] | select(.region == \"us-east\") | .instanceTypes[].sizes[] | select(.size == \"m5.xlarge\") | .valueColumns[] | select(.name == \"linux\") | (.prices.USD | tonumber | . * 3)' 2>/dev/null || echo ''").trim()
            env.PIP_CACHE_DIR = "${WORKSPACE}/.pip-cache"
            env.PYTHONUNBUFFERED = 1
            env.ANSIBLE_TRANSPORT = "paramiko"
            env.ANSIBLE_SSH_CONTROL_PATH = "/var/shm/control:%h:%p:%r"
            env.ANSIBLE_SSH_CONTROL_PATH_DIR = "/var/shm/control"
            env.ANSIBLE_SSH_ARGS = "-C -o PreferredAuthentications=publickey -o ServerAliveInterval=30 -o ControlMaster=auto -o ControlPersist=60s"
          }
          retry(3) {
            sh("pip install -r test_requirements.txt")
          }
          sh("yamllint -c .yamllint.yml .")
          sh("ansible-lint roles/* -v")
        }
      }
    }

    stage('molecule test') {
      parallel {
        stage('molecule test (ec2_centos7) / Open') {
          agent {
            label "py36"
          }
          steps {
            ansiColor('xterm') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh '''
                    export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-centos7-open"
                    export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-centos7-open"
                    export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-centos7-open"

                    rm -rf \${MOLECULE_EPHEMERAL_DIRECTORY} \${ANSIBLE_LOCAL_TEMP} \${ANSIBLE_ASYNC_DIR}
                    pip install -r test_requirements.txt

                    cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml
                    sed -i -e "s/spot_price_max_calc:.*/spot_price_max_calc: \${LINUX_DOUBLE_SPOT_PRICE}/" molecule/ec2/create.yml

                    molecule test --scenario-name ec2_centos7
                  '''
                }
              }
            }
          }
          post {
            aborted {
              ansiColor('xterm') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                  ]) {
                  timeout(time: 20, unit: 'MINUTES') {
                    sh '''
                      export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-centos7-open"
                      export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-centos7-open"
                      export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-centos7-open"

                      molecule destroy --scenario-name ec2_centos7
                    '''
                  }
                }
              }
            }
          }
        }
        stage('molecule test (ec2_centos7) / Enterprise') {
          agent {
            label "py36"
          }
          environment {
            LICENSE = credentials("DCOS_1_13_LICENSE")
          }
          steps {
            ansiColor('xterm') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh '''
                    export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-centos7-enterprise"
                    export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-centos7-enterprise"
                    export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-centos7-enterprise"

                    rm -rf \${MOLECULE_EPHEMERAL_DIRECTORY} \${ANSIBLE_LOCAL_TEMP} \${ANSIBLE_ASYNC_DIR}
                    pip install -r test_requirements.txt

                    cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml
                    set +x; echo 'writing license_key_contents'; sed -i -e \"/config:/a\\    license_key_contents: \$(cat \${LICENSE})\" group_vars/all/dcos.yaml; set -x
                    sed -i -e 's/bootstrap1-centos7/bootstrap1-centos7-enterprise/' -e 's/master1-centos7/master1-centos7-enterprise/' -e 's/agent1-centos7/agent1-centos7-enterprise/' molecule/ec2_centos7/molecule.yml
                    sed -i -e "s/spot_price_max_calc:.*/spot_price_max_calc: \${LINUX_DOUBLE_SPOT_PRICE}/" molecule/ec2/create.yml
                    sed -i 's/download_checksum: .*/download_checksum: sha256:522e461ed1a0779d2b54c91a3904218c79c612da45f3fe8d1623f1925ff9e3da/' group_vars/all/dcos.yaml
                    egrep -r 'downloads.dcos.io/dcos' -l --include='*.yml' --include='*.yaml' . | xargs -I {} sed -i -e 's/enterprise_dcos: .*/enterprise_dcos: true/' -e 's%downloads.dcos.io/dcos%downloads.mesosphere.com/dcos-enterprise%g' -e 's/dcos_generate_config.sh/dcos_generate_config.ee.sh/g' {}

                    molecule test --scenario-name ec2_centos7
                  '''
                }
              }
            }
          }
          post {
            aborted {
              ansiColor('xterm') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                  ]) {
                  timeout(time: 20, unit: 'MINUTES') {
                    sh '''
                      export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-centos7-enterprise"
                      export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-centos7-enterprise"
                      export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-centos7-enterprise"

                      molecule destroy --scenario-name ec2_centos7
                    '''
                  }
                }
              }
            }
          }
        }
        stage('molecule test (ec2_rhel7) / Open') {
          agent {
            label "py36"
          }
          steps {
            ansiColor('xterm') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh '''
                    export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-rhel7-open"
                    export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-rhel7-open"
                    export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-rhel7-open"

                    rm -rf \${MOLECULE_EPHEMERAL_DIRECTORY} \${ANSIBLE_LOCAL_TEMP} \${ANSIBLE_ASYNC_DIR}
                    pip install -r test_requirements.txt

                    cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml
                    sed -i -e \"s/spot_price_max_calc:.*/spot_price_max_calc: \${RHEL_TRIPLE_LINUX_SPOT_PRICE}/" molecule/ec2/create.yml

                    molecule test --scenario-name ec2_rhel7
                  '''
                }
              }
            }
          }
          post {
            aborted {
              ansiColor('xterm') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                  ]) {
                  timeout(time: 20, unit: 'MINUTES') {
                    sh '''
                      export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-rhel7-open"
                      export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-rhel7-open"
                      export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-rhel7-open"

                      molecule destroy --scenario-name ec2_rhel7
                    '''
                  }
                }
              }
            }
          }
        }
        stage('molecule test (ec2_rhel7) / Enterprise') {
          agent {
            label "py36"
          }
          environment {
            LICENSE = credentials("DCOS_1_13_LICENSE")
          }
          steps {
            ansiColor('xterm') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh '''
                    exit 0
                    export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-rhel7-enterprise"
                    export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-rhel7-enterprise"
                    export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-rhel7-enterprise"

                    rm -rf \${MOLECULE_EPHEMERAL_DIRECTORY} \${ANSIBLE_LOCAL_TEMP} \${ANSIBLE_ASYNC_DIR}
                    pip install -r test_requirements.txt

                    cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml
                    set +x; echo 'writing license_key_contents'; sed -i -e \"/config:/a\\    license_key_contents: \$(cat \${LICENSE})\" group_vars/all/dcos.yaml; set -x
                    sed -i -e 's/bootstrap1-rhel7/bootstrap1-rhel7-enterprise/' -e 's/master1-rhel7/master1-rhel7-enterprise/' -e 's/agent1-rhel7/agent1-rhel7-enterprise/' molecule/ec2_rhel7/molecule.yml
                    sed -i -e "s/spot_price_max_calc:.*/spot_price_max_calc: \${RHEL_TRIPLE_LINUX_SPOT_PRICE}/" molecule/ec2/create.yml
                    sed -i 's/download_checksum: .*/download_checksum: sha256:522e461ed1a0779d2b54c91a3904218c79c612da45f3fe8d1623f1925ff9e3da/' group_vars/all/dcos.yaml
                    egrep -r 'downloads.dcos.io/dcos' -l --include='*.yml' --include='*.yaml' . | xargs -I {} sed -i -e 's/enterprise_dcos: .*/enterprise_dcos: true/' -e 's%downloads.dcos.io/dcos%downloads.mesosphere.com/dcos-enterprise%g' -e 's/dcos_generate_config.sh/dcos_generate_config.ee.sh/g' {}

                    molecule test --scenario-name ec2_rhel7
                  '''
                }
              }
            }
          }
          post {
            aborted {
              ansiColor('xterm') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                  ]) {
                  timeout(time: 20, unit: 'MINUTES') {
                    sh '''
                      export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-rhel7-enterprise"
                      export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-rhel7-enterprise"
                      export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-rhel7-enterprise"

                      molecule destroy --scenario-name ec2_rhel7
                    '''
                  }
                }
              }
            }
          }
        }
        stage('molecule test (ec2_gpu) / GPU') {
          when {
            beforeAgent true
            changeset "roles/dcos_gpu/*"
          }
          agent {
            label "py36"
          }
          steps {
            ansiColor('xterm') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                ]) {
                timeout(time: 60, unit: 'MINUTES') {
                  sh '''
                    export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-gpu"
                    export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-gpu"
                    export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-gpu"

                    rm -rf \${MOLECULE_EPHEMERAL_DIRECTORY} \${ANSIBLE_LOCAL_TEMP} \${ANSIBLE_ASYNC_DIR}
                    pip install -r test_requirements.txt

                    cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml

                    molecule test --scenario-name ec2_gpu
                  '''
                }
              }
            }
          }
          post {
            aborted {
              ansiColor('xterm') {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'arn:aws:iam::850970822230:user/jenkins', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                  ]) {
                  timeout(time: 20, unit: 'MINUTES') {
                    sh '''
                      export ANSIBLE_LOCAL_TEMP="${WORKSPACE}/.ansible-tmp-gpu"
                      export ANSIBLE_ASYNC_DIR="${WORKSPACE}/.ansible-async-gpu"
                      export MOLECULE_EPHEMERAL_DIRECTORY="${WORKSPACE}/.molecule-gpu"

                      molecule destroy --scenario-name ec2_gpu
                    '''
                  }
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
            beforeAgent true
            not { changeset "Jenkinsfile" }
            branch 'master'
          }
          agent {
            label "py36"
          }
          environment {
            GALAXY_API_KEY = credentials('dcos-sre-robot-galaxy-ansible-api-token')
          }
          steps {
            retry(3) {
              sh("pip install -r test_requirements.txt")
            }
            sh("if [ -f ./galaxy.yml ]; then mazer build; fi")
            // sh("for i in ./releases/*; do mazer publish --api-key=${GALAXY_API_KEY} \${i}; done")
          }
        }
        stage('hub.docker.com') {
          when {
            beforeAgent true
            not { changeset "Jenkinsfile" }
            not { changeset "galaxy.yml" }
            anyOf {
              branch 'master';
              branch 'feature/*';
            }
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
                env.dockerTag = sh(script: "echo \$(git rev-parse --abbrev-ref HEAD)-\$(git rev-parse --short HEAD)", returnStdout: true).replaceAll('/','-').trim()
                // Tag and push the image we built earlier.
                sh("docker tag mesosphere/${IMAGE}:latest mesosphere/${IMAGE}:${env.dockerTag}")
                sh("docker push mesosphere/${IMAGE}:${env.dockerTag}")
                if (env.BRANCH_NAME == 'master') {
                  // Only overwrite latest if we're on master
                  sh("docker push mesosphere/${IMAGE}:latest")
                }
              }
            }
          }
        }
      }
    }
  }
}

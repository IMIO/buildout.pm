pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment{
        PATH="$PATH:$HOME/geckodriver"
        ZSERVER_PORT="5595"
    }

    stages {
        stage('Build') {
            steps {
                cache(maxCacheSize: 850,
                      caches: [[$class: 'ArbitraryFileCache', excludes: '', path: '${WORKSPACE}/eggs']]){
                            sh 'sed -ie "s#MeetingCommunes.git branch=master#MeetingCommunes.git branch=${BRANCH_NAME}#" communes-dev.cfg'
                            sh 'make jenkins'
                }
                stash 'workspace'
            }
        }

        stage('Run Tests') {
            parallel {
                stage('Unit Test') {
                    steps {
                        dir('unit_test') {
                            unstash 'workspace'
                            sh 'bin/test --test=!robot'
                            sh 'bin/testmc'
                        }
                    }

                }

                stage('Test Coverage') {
                    steps {
                        dir('test_coverage') {
                            unstash 'workspace'
                            sh 'bin/code-analysis'
                            sh 'bin/coverage run --source=Products.PloneMeeting,Products.MeetingCommunes bin/testmc --test=!robot'
                            sh 'bin/coverage xml -i'
                        }
                    }
                }
            }
        }
    }

    post{
        failure{
            mail to: 'pm-interne@imio.be',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "The pipeline${env.JOB_NAME} ${env.BUILD_NUMBER} failed (${env.BUILD_URL})"

            slackSend channel: "#jenkins",
                      color: "#ff0000",
                      message: "Failed ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
        }
        regression{
            mail to: 'pm-interne@imio.be',
                 subject: "Broken Pipeline: ${currentBuild.fullDisplayName}",
                 body: "The pipeline ${env.JOB_NAME} ${env.BUILD_NUMBER} is broken (${env.BUILD_URL})"

            slackSend channel: "#jenkins",
                      color: "#ff0000",
                      message: "Broken ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
        }
        fixed{
            mail to: 'pm-interne@imio.be',
                 subject: "Fixed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "The pipeline ${env.JOB_NAME} ${env.BUILD_NUMBER} is back to normal (${env.BUILD_URL})"

            slackSend channel: "#jenkins",
                      color: "#00cc44",
                      message: "Fixed ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
        }
        cleanup{
            deleteDir()
        }
    }
}
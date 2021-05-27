import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def user;
node {
    
    try {
        //stage('Pull repository from GitHub') {
        // git credentialsId: 'samirans-bs_demo_jenkins', url: 'git@github.com:browserstack/percy-demo.git'
        //}
        //def user;

        stage('Create Percy build and upload snapshots') {
            wrap([$class: 'BuildUser']) {
                user = env.BUILD_USER_ID
                echo "The current user id is: ${user}"
                    withEnv(['BUILD_USER_EMAIL='+ user]) {
            // some block
                    sshagent(['samirans-bs_demo_jenkins']) {  
                        sh label: '', returnStatus: true, script: '''#!/bin/bash -l
                                            cp -r "${JENKINS_HOME}/percy-demo-v2/." "${JENKINS_HOME}/workspace/${JOB_NAME}"
                                            cd "${JENKINS_HOME}/workspace/${JOB_NAME}/percy-demo"
                                            export GITHUB_USER=${GITHUB_USER}
                                            export GITHUB_TOKEN=${GITHUB_TOKEN}
                                            export PERCY_TOKEN=${PERCY_DEMO_PERCY_TOKEN}
                                            export CI_USER_ID=`echo ${BUILD_USER_EMAIL} | cut -d@ -f1`
                                            sh create-demo-pr.sh
                                            cat "${JENKINS_HOME}/jobs/${JOB_NAME}/builds/${BUILD_NUMBER}/log" | grep "finalized build" >> "${JENKINS_HOME}/workspace/${JOB_NAME}/logs/log_${BUILD_NUMBER}.txt"
                                        '''
                    // some block
                    archiveArtifacts artifacts: 'logs/log_${BUILD_NUMBER}.txt', caseSensitive: false, defaultExcludes: false, onlyIfSuccessful: true
                    archiveArtifacts artifacts: 'percy-demo/tests/demo.js', caseSensitive: false, defaultExcludes: false, onlyIfSuccessful: true
                    }
                }
            }
        }
    } catch (e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        //notifySlack(currentBuild.result)
    }
}

def notifySlack(String buildStatus = 'STARTED') {
    // Build status of null means success.
    buildStatus = buildStatus ?: 'SUCCESS'

    def color

    if (buildStatus == 'STARTED') {
        color = '#D4DADF'
    } else if (buildStatus == 'SUCCESS') {
        color = '#BDFFC3'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#FFFE89'
    } else {
        color = '#FF9FA1'
    }
    
    def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"
    if (buildStatus != 'STARTED' && buildStatus !='SUCCESS') {
        slackSend(color: color, message: msg)
    }
}
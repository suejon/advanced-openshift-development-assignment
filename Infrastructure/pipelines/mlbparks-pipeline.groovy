#!groovy
node('maven-appdev') {
    def mvnCmd = "mvn -s ./nexus_openshift_settings.xml"
    
    stage('Checkout Source') {
        git 'https://github.com/suejon/advanced-openshift-development-assignment'
    }
    
    def groupId = getGroupIdFromPom("pom.xml")
    def artifactId = getArtifactIdFromPom("pom.xml")
    def version = getVersionFromPom("pom.xml")
    
    def devTag = "${version}-${BUILD_NUMBER}"
    def prodTag = "${version}"
    
    stage('Build war') {
        echo "Building version ${version}"
        // sh "${mvnCmd} package -DskipTests"
    }
    
    stage('Unit Tests') {
        echo "Running Unit Tests"
        // sh "${mvnCmd} test"
    }
    
    stage('Code Analysis') {
        echo "Running Code Analysis"
        // sh 'mvn sonar:sonar -s ./nexus_openshift_settings.xml -Dsonar.host.url=http://sonarqube-js-sonarqube.apps.wlg.example.opentlc.com'
    }
    
    stage("Publish to Nexus") {
        echo "Publish to Nexus"
        // sh 'mvn -s ./nexus_openshift_settings.xml deploy -DskipTests=true -DaltDeploymentRepository=nexus::default::http://nexus3-js-nexus.apps.wlg.example.opentlc.com/repository/releases'
    }
    
    stage("Build and Tag Openshift Image") {
        echo "Building OpenShift container image tasks:${devTag}"
        // sh "oc start-build tasks --from-file=http://nexus3-js-nexus.apps.wlg.example.opentlc.com/repository/releases/org/jboss/quickstarts/eap/tasks/${version}/tasks-${version}.war -n js-tasks-dev"
        // // to tag the image
        // openshiftTag alias: 'false', apiURL: 'https://master.wlg.example.opentlc.com', authToken: 'qKdqvB9ezVQxcPPtvmhGARG9id2519UhBEmp8YCuXEk', destStream: 'tasks', destTag: devTag, destinationAuthToken: 'qKdqvB9ezVQxcPPtvmhGARG9id2519UhBEmp8YCuXEk', destinationNamespace: 'js-tasks-dev', namespace: 'js-tasks-dev', srcStream: 'tasks', srcTag: 'latest', verbose: 'false'
    }
    
    stage('Deploy to Dev') {
        echo "Deploying container image to Development Project"
        // sh "oc set image dc/tasks tasks=docker-registry.default.svc:5000/js-tasks-dev/tasks:${devTag} -n js-tasks-dev"
        // sh "oc delete configmap tasks-config --ignore-not-found=true -n js-tasks-dev"
        // sh "oc create configmap tasks-config --from-file=configuration/application-users.properties --from-file=configuration/application-roles.properties -n js-tasks-dev"
        
        // openshiftDeploy apiURL: 'https://master.wlg.example.opentlc.com', authToken: 'qKdqvB9ezVQxcPPtvmhGARG9id2519UhBEmp8YCuXEk', depCfg: 'tasks', namespace: 'js-tasks-dev', verbose: 'false', waitTime: '', waitUnit: 'sec'
        // openshiftVerifyDeployment apiURL: 'https://master.wlg.example.opentlc.com', authToken: 'qKdqvB9ezVQxcPPtvmhGARG9id2519UhBEmp8YCuXEk', depCfg: 'tasks', namespace: 'js-tasks-dev', replicaCount: '', verbose: 'false', verifyReplicaCount: 'true', waitTime: '', waitUnit: 'sec'
        // openshiftVerifyService apiURL: 'https://master.wlg.example.opentlc.com', authToken: 'qKdqvB9ezVQxcPPtvmhGARG9id2519UhBEmp8YCuXEk', namespace: 'js-tasks-dev', svcName: 'tasks', verbose: 'false'
    }
    
    stage('Integration Tests') {
        echo "Running Integration Tests"
        // sleep 15

        // // Create a new task called "integration_test_1"
        // echo "Creating task"
        // sh "curl -i -u 'tasks:redhat1' -H 'Content-Length: 0' -X POST http://tasks.js-tasks-dev.svc.cluster.local:8080/ws/tasks/integration_test_1"

        // // Retrieve task with id "1"
        // echo "Retrieving tasks"
        // sh "curl -i -u 'tasks:redhat1' -H 'Content-Length: 0' -X GET http://tasks.js-tasks-dev.svc.cluster.local:8080/ws/tasks/1"

        // // Delete task with id "1"
        // echo "Deleting tasks"
        // sh "curl -i -u 'tasks:redhat1' -H 'Content-Length: 0' -X DELETE http://tasks.js-tasks-dev.svc.cluster.local:8080/ws/tasks/1"
    }
    
    stage('Copy Image to Nexus Docker Registry') {
        echo "Copy image to Nexus Docker Registry"
        // sh "skopeo copy --src-tls-verify=false --dest-tls-verify=false --src-creds openshift:\$(oc whoami -t) --dest-creds admin:admin123 docker://docker-registry.default.svc.cluster.local:5000/js-tasks-dev/tasks:${devTag} docker://nexus-registry.js-nexus.svc.cluster.local:5000/tasks:${devTag}"

        // openshiftTag alias: 'false', destStream: 'tasks', destTag: prodTag, destinationNamespace: 'js-tasks-dev', namespace: 'js-tasks-dev', srcStream: 'tasks', srcTag: devTag, verbose: 'false'
    }
    
    def destApp = "tasks-green"
    def activeApp = ""
    
    stage('Blue/Green Production Deployment') {
        // activeApp = sh(returnStdout: true, script: "oc get route tasks -n js-tasks-prod -o jsonpath='{ .spec.to.name }'").trim()
        // if (activeApp == "tasks-green") {
        //     destApp = "tasks-blue"
        // }
        // echo "Active Application:      " + activeApp
        // echo "Destination Application: " + destApp

        // // Update the Image on the Production Deployment Config
        // sh "oc set image dc/${destApp} ${destApp}=docker-registry.default.svc:5000/js-tasks-dev/tasks:${prodTag} -n js-tasks-prod"

        // // Update the Config Map which contains the users for the Tasks application
        // sh "oc delete configmap ${destApp}-config -n js-tasks-prod --ignore-not-found=true"
        // sh "oc create configmap ${destApp}-config --from-file=./configuration/application-users.properties --from-file=./configuration/application-roles.properties -n js-tasks-prod"

        // // Deploy the inactive application.
        // // Replace xyz-tasks-prod with the name of your production project
        // openshiftDeploy depCfg: destApp, namespace: 'js-tasks-prod', verbose: 'false', waitTime: '', waitUnit: 'sec'
        // openshiftVerifyDeployment depCfg: destApp, namespace: 'js-tasks-prod', replicaCount: '1', verbose: 'false', verifyReplicaCount: 'true', waitTime: '', waitUnit: 'sec'
        // openshiftVerifyService namespace: 'js-tasks-prod', svcName: destApp, verbose: 'false'
    }
    
    stage('Switch over to new Version') {
        echo "Switching Production application to ${destApp}"
        // input "Switch Production?"
        // echo "Switching Production application to ${destApp}."
        // // Replace xyz-tasks-prod with the name of your production project
        // sh 'oc patch route tasks -n js-tasks-prod -p \'{"spec":{"to":{"name":"' + destApp + '"}}}\''
    }
}

def getVersionFromPom(pom) {
  def matcher = readFile(pom) =~ '<version>(.+)</version>'
  matcher ? matcher[0][1] : null
}
def getGroupIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<groupId>(.+)</groupId>'
  matcher ? matcher[0][1] : null
}
def getArtifactIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<artifactId>(.+)</artifactId>'
  matcher ? matcher[0][1] : null
}
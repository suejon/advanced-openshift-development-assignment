#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

# create objects
# oc new-app ../templates/jenkins/jenkins_template.yaml -n ${GUID}-jenkins
oc new-app jenkins-persistent --name jenkins --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n ${GUID}-jenkins

# create jenkins slave image with skopeo
cat ../templates/jenkins/Dockerfile | oc new-build --dockerfile=- --name=jenkins-slave-maven-appdev -n ${GUID}-jenkins
# oc start-build jenkins-slave-maven-appdev -n ${GUID}-jenkins

# set up 3 BCs that point to the pipelines located in source code
oc create -f ../templates/jenkins/mlbparks_bc.yaml -n ${GUID}-jenkins
oc create -f ../templates/jenkins/nationalparks_bc.yaml -n ${GUID}-jenkins
oc create -f ../templates/jenkins/parksmap_bc.yaml -n ${GUID}-jenkins

# set environmental variables in build configs for pipeline: GUID, Cluster
oc set env bc/mlbparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
oc set env bc/nationalparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
oc set env bc/parksmap-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
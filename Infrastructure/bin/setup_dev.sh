#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
ParksMap="parksmap"
MlbParks="mlbparks"
NationalParks="nationalparks"
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

# Set up Dev Application

oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev

oc new-app -f ./Infrastructure/templates/parks-dev/mongodb_services.yaml -n ${GUID}-parks-dev
oc create -f ./Infrastructure/templates/parks-dev/mongodb_statefulset.yaml -n ${GUID}-parks-dev

oc expose svc/mongodb-internal -n ${GUID}-parks-dev
oc expose svc/mongodb -n ${GUID}-parks-dev

# set up binary builds ready to use the war files built from the pipeline
oc new-build --binary=true --name=${ParksMap} redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-build --binary=true --name=${MlbParks} jboss-eap70-openshift:1.6 -n ${GUID}-parks-dev
oc new-build --binary=true --name=${NationalParks} redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev

# set up config maps for each micro-service
oc create configmap ${ParksMap}-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=ParksMap (Dev)" -n ${GUID}-parks-dev
oc create configmap ${MlbParks}-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=MLB Parks (Dev)" -n ${GUID}-parks-dev
oc create configmap ${NationalParks}-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=National Parks (Dev)" -n ${GUID}-parks-dev

# set up placeholder deployments
oc new-app ${GUID}-parks-dev/${ParksMap}:0.0-0 --name=${ParksMap} --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/${MlbParks}:0.0-0 --name=${MlbParks} --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/${NationalParks}:0.0-0 --name=${NationalParks} --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

# set environmental variables for connecting to mongo db
oc set env dc/${MlbParks} DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 --from=configmap/${MlbParks}-config -n ${GUID}-parks-dev
oc set env dc/${NationalParks} DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 --from=configmap/${NationalParks}-config -n ${GUID}-parks-dev
oc set env dc/${ParksMap} --from=configmap/${ParksMap}-config -n ${GUID}-parks-dev

# configure mount path and apply configurationmaps to each service
oc set volume dc/${ParksMap} --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=${ParksMap}-config -n ${GUID}-parks-dev
oc set volume dc/${ParksMap} --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=${ParksMap}-config -n ${GUID}-parks-dev

oc set volume dc/${MlbParks} --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=${MlbParks}-config -n ${GUID}-parks-dev
oc set volume dc/${MlbParks} --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=${MlbParks}-config -n ${GUID}-parks-dev

oc set volume dc/${NationalParks} --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=${NationalParks}-config -n ${GUID}-parks-dev
oc set volume dc/${NationalParks} --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=${NationalParks}-config -n ${GUID}-parks-dev

# set up deployment hooks so the backend services can be populated
oc set triggers dc/${ParksMap} --remove-all -n ${GUID}-parks-dev
oc set triggers dc/${MlbParks} --remove-all -n ${GUID}-parks-dev
oc set triggers dc/${NationalParks} --remove-all -n ${GUID}-parks-dev

# set up health probes
oc set probe dc/${ParksMap} -n ${GUID}-parks-dev --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${ParksMap} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc set probe dc/${MlbParks} -n ${GUID}-parks-dev --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${MlbParks} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc set probe dc/${NationalParks} -n ${GUID}-parks-dev --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${NationalParks} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

# expose and label the services so the front end (${ParksMap}) can find them
oc expose dc ${ParksMap} --port 8080 -n ${GUID}-parks-dev
oc expose svc ${ParksMap} -n ${GUID}-parks-dev

oc expose dc ${MlbParks} --port 8080 -n ${GUID}-parks-dev
oc expose svc ${MlbParks} --labels="type=parksmap-backend" -n ${GUID}-parks-dev

oc expose dc ${NationalParks} --port 8080 -n ${GUID}-parks-dev
oc expose svc ${NationalParks} --labels="type=parksmap-backend" -n ${GUID}-parks-dev
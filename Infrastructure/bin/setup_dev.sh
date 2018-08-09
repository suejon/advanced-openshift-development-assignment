#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

# Set up Dev Application

oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev

oc new-app -f ../templates/parks-dev/mongodb_services.yaml -n ${GUID}-parks-dev
oc create -f ../templates/parks-dev/mongodb_statefulset.yaml -n ${GUID}-parks-dev

oc expose svc/mongodb-internal -n ${GUID}-parks-dev
oc expose svc/mongodb -n ${GUID}-parks-dev

# set up binary builds ready to use the war files built from the pipeline
oc new-build --binary=true --name="parks-map" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-build --binary=true --name="mlb-parks" jboss-eap70-openshift:1.6 -n ${GUID}-parks-dev
oc new-build --binary=true --name="national-parks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev

# set up config maps for each micro-service
oc create configmap parks-map-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=MLB Parks (Dev)" -n ${GUID}-parks-dev
oc create configmap mlb-parks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=National Parks (Dev)" -n ${GUID}-parks-dev
oc create configmap national-parks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=ParksMap (Dev)" -n ${GUID}-parks-dev

# set up placeholder deployments
oc new-app ${GUID}-parks-dev/parks-map:0.0-0 --name=parks-map --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/mlb-parks:0.0-0 --name=mlb-parks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/national-parks:0.0-0 --name=national-parks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

# set environmental variables for connecting to mongo db
oc set env dc/mlb-parks DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 -n ${GUID}-parks-dev
oc set env dc/national-parks DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 -n ${GUID}-parks-dev

# configure mount path and apply configurationmaps to each service
oc set volume dc/parks-map --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=parks-map-config -n ${GUID}-parks-dev
oc set volume dc/parks-map --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=parks-map-config -n ${GUID}-parks-dev

oc set volume dc/mlb-parks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=mlb-parks-config -n ${GUID}-parks-dev
oc set volume dc/mlb-parks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=mlb-parks-config -n ${GUID}-parks-dev

oc set volume dc/national-parks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=national-parks-config -n ${GUID}-parks-dev
oc set volume dc/national-parks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=national-parks-config -n ${GUID}-parks-dev

# set up deployment hooks so the backend services can be populated
oc set triggers dc/parks-map --remove-all -n ${GUID}-parks-dev
oc set triggers dc/mlb-parks --remove-all -n ${GUID}-parks-dev
oc set triggers dc/national-parks --remove-all -n ${GUID}-parks-dev

# set up health probes
oc set probe dc/parks-map -n ${GUID}-parks-dev --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/parks-map --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc set probe dc/mlb-parks -n ${GUID}-parks-dev --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/mlb-parks --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc set probe dc/national-parks -n ${GUID}-parks-dev --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/national-parks --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

# expose and label the services so the front end (parks-map) can find them
oc expose dc parks-map --port 8080 -n ${GUID}-parks-dev
oc expose svc parks-map -n ${GUID}-parks-dev

oc expose dc mlb-parks --port 8080 -n ${GUID}-parks-dev
oc expose svc mlb-parks --labels="type=parksmap-backend" -n ${GUID}-parks-dev

oc expose dc national-parks --port 8080 -n ${GUID}-parks-dev
oc expose svc national-parks --labels="type=parksmap-backend" -n ${GUID}-parks-dev
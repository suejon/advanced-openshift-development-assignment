#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod

# spin up mongo db via stateful set
oc new-app -f ../templates/parks-prod/mongodb_services.yaml -n ${GUID}-parks-prod
oc create -f ../templates/parks-prod/mongodb_statefulset.yaml -n ${GUID}-parks-prod

oc expose svc/mongodb-internal -n ${GUID}-parks-prod
oc expose svc/mongodb -n ${GUID}-parks-prod


# Create Blue/Green Applications
## MLB Parks
### Blue
oc new-app ${GUID}-parks-dev/mlb-parks:0.0 --name=mlb-parks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlb-parks-blue --remove-all -n ${GUID}-parks-prod
oc expose dc mlb-parks-blue --port 8080 -n ${GUID}-parks-prod
oc create configmap mlb-parks-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=MLB Parks (Blue)" -n ${GUID}-parks-prod
oc set volume dc/mlb-parks-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=mlb-parks-blue-config -n ${GUID}-parks-prod
oc set volume dc/mlb-parks-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=mlb-parks-blue-config -n ${GUID}-parks-prod
### Green
oc new-app ${GUID}-parks-dev/mlb-parks:0.0 --name=mlb-parks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlb-parks-green --remove-all -n ${GUID}-parks-prod
oc expose dc mlb-parks-green --port 8080 -n ${GUID}-parks-prod
oc create configmap mlb-parks-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=MLB Parks (Green)" -n ${GUID}-parks-prod
oc set volume dc/mlb-parks-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=mlb-parks-green-config -n ${GUID}-parks-prod
oc set volume dc/mlb-parks-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=mlb-parks-green-config -n ${GUID}-parks-prod   

## National Parks
### Blue
oc new-app ${GUID}-parks-dev/national-parks:0.0 --name=national-parks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/national-parks-blue --remove-all -n ${GUID}-parks-prod
oc expose dc national-parks-blue --port 8080 -n ${GUID}-parks-prod
oc create configmap national-parks-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=National Parks (Blue)" -n ${GUID}-parks-prod
oc set volume dc/national-parks-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=national-parks-blue-config -n ${GUID}-parks-prod
oc set volume dc/national-parks-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=national-parks-blue-config -n ${GUID}-parks-prod
### Green
oc new-app ${GUID}-parks-dev/national-parks:0.0 --name=national-parks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/national-parks-green --remove-all -n ${GUID}-parks-prod
oc expose dc national-parks-green --port 8080 -n ${GUID}-parks-prod
oc create configmap national-parks-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=National Parks (Green)" -n ${GUID}-parks-prod
oc set volume dc/national-parks-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=national-parks-green-config -n ${GUID}-parks-prod
oc set volume dc/national-parks-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=national-parks-green-config -n ${GUID}-parks-prod

## ParksMap
### Blue
oc new-app ${GUID}-parks-dev/parks-map:0.0 --name=parks-map-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/parks-map-blue --remove-all -n ${GUID}-parks-prod
oc expose dc parks-map-blue --port 8080 -n ${GUID}-parks-prod
oc create configmap parks-map-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=ParksMap (Blue)" -n ${GUID}-parks-prod
oc set volume dc/parks-map-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=parks-map-blue-config -n ${GUID}-parks-prod
oc set volume dc/parks-map-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=parks-map-blue-config -n ${GUID}-parks-prod
### Green
oc new-app ${GUID}-parks-dev/parks-map:0.0 --name=parks-map-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/parks-map-green --remove-all -n ${GUID}-parks-prod
oc expose dc parks-map-green --port 8080 -n ${GUID}-parks-prod
oc create configmap parks-map-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" --from-literal="APPNAME=ParksMap (Green)" -n ${GUID}-parks-prod
oc set volume dc/parks-map-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=parks-map-green-config -n ${GUID}-parks-prod
oc set volume dc/parks-map-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=parks-map-green-config -n ${GUID}-parks-prod

# Set environmental variables for connecting to the db
oc set env dc/mlb-parks-green DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set env dc/mlb-parks-blue DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set env dc/national-parks-green DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 -n ${GUID}-parks-prod
oc set env dc/national-parks-blue DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=mongodb DB_PASSWORD=mongodb DB_NAME=mongodb DB_REPLICASET=rs0 -n ${GUID}-parks-prod


# Expose Green service as route to make blue application active
oc expose svc/parks-map-green --name parks-map -n ${GUID}-parks-prod
oc expose svc/mlb-parks-green --name mlb-parks -n ${GUID}-parks-prod
oc expose svc/national-parks-green --name national-parks -n ${GUID}-parks-prod

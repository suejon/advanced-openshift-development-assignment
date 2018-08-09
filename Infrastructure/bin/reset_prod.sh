#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student

# delete + create blue services (w/o labels)
echo "Removing labels from blue services so they are no longer used as active backends"
oc delete svc mlb-parks-blue -n ${GUID}-parks-prod
oc delete svc national-parks-blue -n ${GUID}-parks-prod
oc create -f ../templates/parks-prod/mlb-parks-blue-svc.yaml -n ${GUID}-parks-prod
oc create -f ../templates/parks-prod/national-parks-blue-svc.yaml -n ${GUID}-parks-prod

# Switch parks-map route to point back to green
echo "Directing traffic back to green deployments"
oc patch route mlb-parks --patch='{"spec":{"to":{"name": "mlb-parks-green"}}}' -n ${GUID}-parks-prod
oc patch route national-parks --patch='{"spec":{"to":{"name": "national-parks-green"}}}' -n ${GUID}-parks-prod
oc patch route parks-map --patch='{"spec":{"to":{"name": "parks-map-green"}}}' -n ${GUID}-parks-prod

# label green services with correct labels: app and type
echo "Label the green services as the active backends"
oc label svc mlb-parks-green type=parksmap-backend --overwrite -n ${GUID}-parks-prod
oc label svc national-parks-green type=parksmap-backend --overwrite -n ${GUID}-parks-prod

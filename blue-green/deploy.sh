#!/bin/bash

###############################################################################
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2016. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
###############################################################################

# This script deploys the new version of the app to the blue (test) route.
# All environment variables defined in the Pipeline stage are set on the app.
# This script should be executed from the base directory intended to be pushed.

SCRIPT_DIR=`dirname $BASH_SOURCE`

. $SCRIPT_DIR/app-names.sh
. $SCRIPT_DIR/colors.sh

if [ -z "$INSTANCES" ]; then
    INSTANCES=1
fi
if [ -z "$MEMORY" ]; then
    MEMORY=256M
fi
 
function main {
    # delete the old blue app so env vars don't persist
    if cf app $BLUE; then
        if ! cf delete -f $BLUE; then
            error "Error deleting the old blue app"
        fi
    fi
    
    # push the app
    if ! cf push "$BLUE" -d "$DOMAIN" -i "$INSTANCES" -m $MEMORY --no-route --no-start; then
        error "Error pushing this app."
    fi

    # set the environment properties from stage environment vars
    IFS=',' read -ra PROP <<< "$IDS_OUTPUT_PROPS"
    for p in "${PROP[@]}"; do
        set_env "$p"
    done

    # Set the build version info for the /version endpoint.
    if [ -f ".pipeline_build_id" ]; then
        cf set-env $BLUE BUILD_NUMBER "$(<.pipeline_build_id)" || exit 1
    fi

    # add a blue route for testing
    if ! cf map-route "$BLUE" "$DOMAIN" -n "$BLUE"; then
        error "Could not add unsuffixed route to this app."
    fi
    
    # restart app
    if ! cf restart "$BLUE"; then 
        error "Error restarting this app." 
    fi

    # test the new app before allowing future routing changes
    if [ -e "$SCRIPT_DIR/test.sh" ]; then
        $SCRIPT_DIR/test.sh
    fi
}

function set_env {
    name=$1
    value=${!name}

    if ! [ "$value" ]; then
        error "Required environment variable, '$name', is not specified."
    fi
    
    if ! cf set-env $BLUE $name "$value" > /dev/null 2>&1; then
        error "Error setting environment property '$name'"
    fi 
}

function error {
    echo -e "${red}$1${no_color}" >&2
    exit 1
}

main
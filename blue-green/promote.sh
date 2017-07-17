#!/bin/bash

###############################################################################
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2016. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
###############################################################################

# This script transitions the blue (test) app to the green (production) app with no downtime.

SCRIPT_DIR=`dirname $BASH_SOURCE`

. $SCRIPT_DIR/app-names.sh
. $SCRIPT_DIR/colors.sh

# rename current/old app if it exists
unset OLD_APP_EXISTS
if cf app "$GREEN" >/dev/null 2>&1; then  
		OLD_APP_EXISTS=true
fi

# Rename the old green so we can retain it.
if $EXISTING_APP; then
		cf rename "$GREEN" "$GREY"
fi

# rename new app to green
cf rename "$BLUE" "$GREEN"

# add the green to the new app
cf map-route "$GREEN" "$DOMAIN" -n "$CF_APP"

# remove blue route from new app
cf unmap-route "$GREEN" "$DOMAIN" -n "$BLUE"

if [ $OLD_APP_EXISTS ]; then
		# add the blue route to the old app
		cf map-route "$GREY" "$DOMAIN" -n "$BLUE"

		# wait for the new app to route
		sleep 120

		# remove green from old app
		cf unmap-route "$GREY" "$DOMAIN" -n "$CF_APP"

		# rename old app to blue
		cf rename "$GREY" "$BLUE"

		# wait for an inflight requests to finish before stopping
		sleep 30
			
		# stop old app
		cf stop "$BLUE"
fi

if [ $NEW_RELIC_API_KEY -a $NEW_RELIC_APP_NAME ]; then
		# track deployment in new relic
		curl -H "x-api-key:${NEW_RELIC_API_KEY}" -d "deployment[app_name]=${NEW_RELIC_APP_NAME}" -d "deployment[description]=${BUILD_DISPLAY_NAME}" https://api.newrelic.com/deployments.xml
fi

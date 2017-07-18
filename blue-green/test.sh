#!/bin/bash

###############################################################################
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2016. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
###############################################################################

SCRIPT_DIR=`dirname $0`

. $SCRIPT_DIR/app-names.sh
. $SCRIPT_DIR/colors.sh

if [ -z $DOMAIN ]; then
    echo -e "\n${label_color}Testing new app - ${red}No DOMAIN defined. Unable to curl test the newly deployed app.${no_color}"
    exit 0
fi
if [ -z $TEST_PATH ]; then
    echo -e "\n${label_color}Testing new app - ${red}No TEST_PATH defined. Unable to curl test the newly deployed app.${no_color}"
    exit 0
fi

TEST_URL="https://$BLUE.$DOMAIN/$TEST_PATH"

echo -e "\n${label_color}Testing new app - ${green}$TEST_URL${no_color}"

MAX_RETRIES=10
RETRY_DELAY=5
TEST_RETRIES=0

# while instead of curl --retry to support 404 responses
while [ $TEST_RETRIES -lt $MAX_RETRIES ]
do
    CURL_STATUS=0
    # -k: Accept self-signed certs.
    # -s: Disable the status bar.
    # -v: Display the entire conversation.
    # > $TMPDIR/curl.log 2>&1: stdout and stderr go to file
    curl --max-time 30 -k  -s  -v "$TEST_URL" > $TMPDIR/curl.log 2>&1
    # grep: Expect 200 response
    grep -q 'HTTP/.*200 OK' $TMPDIR/curl.log || CURL_STATUS=$?
    if [ $TEST_STATUS_PASS ]; then
        # status returns JSON and we check to make sure it is PASS since it defaults to INCOMPLETE and could be FAIL
        if [[ $CURL_STATUS -eq 0 ]]; then
            grep -q '^{"status":"PASS"' $TMPDIR/curl.log || CURL_STATUS=1
        fi
    fi
    if [ $TEST_STATUS_NUMERIC ]; then
        # status returns JSON and we check to make sure the status in it is a numeric of 0 and not 1
        if [[ $CURL_STATUS -eq 0 ]]; then
            grep -q '"status":0' $TMPDIR/curl.log || CURL_STATUS=1
            grep -q '"status":1' $TMPDIR/curl.log && CURL_STATUS=1
        fi
    fi
    if [[ $CURL_STATUS -ne 0 ]]; then
        echo -e "\nFailed Test Attempt Log:"
        echo -e "================================================================================"
        cat $TMPDIR/curl.log
        echo -e "================================================================================"
        TEST_RETRIES=`expr $TEST_RETRIES + 1`
        sleep $RETRY_DELAY
    else
        TEST_RETRIES=$MAX_RETRIES
    fi
done

# Check and handle curl test failures
if [[ $CURL_STATUS -ne 0 ]]; then
    echo -e "\nFailed Test Attempt Log:"
    echo -e "================================================================================"
    cat $TMPDIR/curl.log
    echo -e "================================================================================"
cat >&2 <<DONE
$0: Even though cf claims the app is running, cannot access $TEST_URL
DONE
    echo -e "${red}New app at $TEST_URL is NOT responding - ${green}$BLUE${no_color}"
    echo -e "\nApplication Logs:"
    echo -e "================================================================================"
    cf logs --recent $BLUE
    echo -e "================================================================================"
    cf stop $BLUE
    exit 1
fi

echo -e "${green}New app at $TEST_URL is responding${no_color}"

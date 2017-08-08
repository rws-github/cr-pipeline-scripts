#!/bin/bash

###############################################################################
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2016. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
###############################################################################

SCRIPT_DIR=`dirname $BASH_SOURCE`
PREVIOUS_DIR=`pwd`

echo "Updating Cloudant database $CLOUDANT_DB with design documents in $DESIGN_DIR"

cd $SCRIPT_DIR
npm install
npm start
cd $PREVIOUS_DIR

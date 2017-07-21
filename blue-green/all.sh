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

./$SCRIPT_DIR/deploy.sh | while IFS= read -r line; do echo "$(date '+%Y-%m-%d %T %Z') [deploy] - $line"; done
./$SCRIPT_DIR/test.sh | while IFS= read -r line; do echo "$(date '+%Y-%m-%d %T %Z') [test] - $line"; done
./$SCRIPT_DIR/promote.sh | while IFS= read -r line; do echo "$(date '+%Y-%m-%d %T %Z') [promote] - $line"; done

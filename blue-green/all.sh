#!/bin/bash -x

###############################################################################
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2016. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
###############################################################################

set -x

SCRIPT_DIR=`dirname $0`

./$SCRIPT_DIR/deploy.sh
./$SCRIPT_DIR/test.sh
./$SCRIPT_DIR/promote.sh

#!/bin/sh
set -o nounset -o errexit

METADATA="$(curl http://169.254.169.254/latest/dynamic/instance-identity/document 2>/dev/null)"
REGION=$(echo $METADATA | grep -Po "\"region\"\s+:\s+\"(.*?)\"" | cut -f2 -d:)
ZONE=$(echo $METADATA | grep -Po "\"availabilityZone\"\s+:\s+\"(.*?)\"" | cut -f2 -d:)

echo "{\"fault_domain\":{\"region\":{\"name\": $REGION},\"zone\":{\"name\": $ZONE}}}"

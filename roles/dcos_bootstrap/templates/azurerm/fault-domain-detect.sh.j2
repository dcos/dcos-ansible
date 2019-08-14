#!/bin/bash
set -o nounset -o errexit

AZURE_REGION_URL="http://169.254.169.254/metadata/instance/compute/location?api-version=2018-10-01&format=text"
AZURE_FD_URL="http://169.254.169.254/metadata/instance/compute/platformFaultDomain?api-version=2018-10-01&format=text"

REGION=$(curl -f -m3 -H Metadata:true "$AZURE_REGION_URL" 2>/dev/null)
rc=$?
if [ $rc -ne 0 ]; then
  echo "unable to fetch azure region. URL $AZURE_REGION_URL. Ret code $rc" >&2
  exit 1
fi

FAULT_DOMAIN=$(curl -f -m3 -H Metadata:true "$AZURE_FD_URL" 2>/dev/null)
rc=$?
if [ $rc -ne 0 ]; then
  echo "unable to fetch azure fault domain. URL $AZURE_FD_URL. Ret code $rc" >&2
  exit 1
fi

echo "{\"fault_domain\":{\"region\":{\"name\": \"azure/$REGION\"},\"zone\":{\"name\": \"azure/$REGION-$FAULT_DOMAIN\"}}}"

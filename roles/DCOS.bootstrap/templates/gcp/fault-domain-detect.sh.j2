#!/usr/bin/env sh
set -o nounset -o errexit

GCP_METADATA_URL="http://169.254.169.254/computeMetadata/v1/instance/zone"
BODY=$(curl -f -m3 -H "Metadata-Flavor: Google" "$GCP_METADATA_URL" 2>/dev/null)
rc=$?
if [ $rc -ne 0 ]; then
  echo "unable to fetch gcp metadata. URL $GCP_METADATA_URL. Ret code $rc" >&2
  exit 1
fi

ZONE=$(echo "$BODY" | sed 's@^projects/.*/zones/\(.*\)$@\1@')
REGION=$(echo "$ZONE" | sed 's@\(.*-.*\)-.*@\1@')

echo "{\"fault_domain\":{\"region\":{\"name\": \"gcp/$REGION\"},\"zone\":{\"name\": \"gcp/$ZONE\"}}}"

#!/bin/bash

if ! curl -s -f -X POST -F "benchmark=@/tmp/files/test.hf.yaml;filename=test.hf.yaml" http://$HYPERFOIL_IP:8090/benchmark ; then
    echo "Cannot upload benchmark"
    exit 1
fi
RUN_URL=$(curl -s http://$HYPERFOIL_IP:8090/benchmark/$TEST_NAME/start -D - -o /tmp/response | grep -i -e 'Location: ')
RUN_ID=$(basename "$RUN_URL" | tr -c -d '[:alnum:]')
if [ -z "$RUN_ID" ]; then
   cat /tmp/response
   exit 1;
fi
while :
do
    if ! curl -f -s http://$HYPERFOIL_IP:8090/run/$RUN_ID -o /tmp/info ; then
        cat /tmp/info
        exit 1
    fi
    COMPLETED=$(cat /tmp/info | jq -r .completed)
    if [ "$COMPLETED" == "true" ]; then
        break
    fi
done
curl -s http://$HYPERFOIL_IP:8090/run/$RUN_ID/stats/all -H 'Accept: application/json'
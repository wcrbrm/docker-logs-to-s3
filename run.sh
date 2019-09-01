#!/bin/bash
set -e
FN=logs-`date +%Y%m%dT%H%M`

if [[ "$AWS_PROFILE" == "" ]]; then
    AWS_PROFILE=default
fi
if [[ "$S3_LOG_PATH" == "" ]]; then
    echo "error: please provide S3_LOG_PATH variable, i.e. s3://example-bucket/igw-logs/"
    exit 1;
fi

mkdir -p out
[[ -e *.tar.gz ]] && find *.tar.gz -exec rm -rf {} \;
[[ -e out/*.log ]] && find out/*.log -exec rm -rf {} \; 

LIST=$(docker ps --format '{{.ID}};{{.Names}}')
for L in $LIST; do
    export PID=$(echo $L | cut -f1 -d';' )
    export NAME=$(echo $L | cut -f2 -d';' | sed s/_/--/g )
    echo PID=$PID,NAME=$NAME
    docker logs $PID > out/$NAME.log 2>&1
done;

ls -All out/
tar zcf $FN.tar.gz out/*.log

aws s3 cp --profile=$AWS_PROFILE $FN.tar.gz $S3_LOG_PATH

rm -f $FN.tar.gz
rm -rf out
aws s3 ls --profile=$AWS_PROFILE $S3_LOG_PATH

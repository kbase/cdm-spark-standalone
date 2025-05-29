#!/bin/bash

mc alias set minio http://minio:9002 minio minio123

# make deltalake bucket
if ! mc ls minio/cdm-lake 2>/dev/null; then
  mc mb minio/cdm-lake && echo 'Bucket cdm-lake created'
else
  echo 'bucket cdm-lake already exists'
fi

# make spark events bucket
if ! mc ls minio/cdm-spark-events 2>/dev/null; then
  mc mb minio/cdm-spark-events && echo 'Bucket cdm-spark-events created'
else
  echo 'bucket cdm-spark-events already exists'
fi

# create spark-events directory inside the bucket
# Create a dummy file to ensure the directory exists, then remove it
echo "dummy" | mc pipe minio/cdm-spark-events/spark-events/.dummy
echo 'spark-events directory created in cdm-spark-events bucket'

# create policies
mc admin policy create minio cdm-read-write-policy /config/cdm-read-write-policy.json
mc admin policy create minio cdm-spark-events-policy /config/cdm-spark-events-policy.json

# make read/write user
mc admin user add minio minio-readwrite minio123
mc admin policy attach minio cdm-read-write-policy --user=minio-readwrite
mc admin policy attach minio cdm-spark-events-policy --user=minio-readwrite
echo 'CDM read-write user and policy set'

# make spark events log access user
mc admin user add minio minio-log-access minio123
mc admin policy attach minio cdm-spark-events-policy --user=minio-log-access
echo 'Spark events log access user and policy set'
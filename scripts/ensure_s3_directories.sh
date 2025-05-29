#!/bin/bash

# Script to ensure S3 directories exist for Spark job logs
# This script is called from setup.sh when SPARK_JOB_LOG_DIR is set

if [ -z "$SPARK_JOB_LOG_DIR" ]; then
    echo "SPARK_JOB_LOG_DIR not set, skipping directory creation"
    exit 0
fi

if [ -z "$MINIO_URL" ] || [ -z "$MINIO_LOG_USER_ACCESS_KEY" ] || [ -z "$MINIO_LOG_USER_SECRET_KEY" ]; then
    echo "MinIO credentials not set, exiting"
    exit 1
fi

# Set MinIO client config directory to a writable location
export MC_CONFIG_DIR="/tmp/.mc"
mkdir -p "$MC_CONFIG_DIR"

if [ -z "$SPARK_JOB_LOG_DIR_CATEGORY" ]; then
    echo "SPARK_JOB_LOG_DIR_CATEGORY not set"
    FULL_S3_PATH="$SPARK_JOB_LOG_DIR"
    SPARK_JOB_LOG_DIR_CATEGORY="default"
else
    FULL_S3_PATH="${SPARK_JOB_LOG_DIR}/${SPARK_JOB_LOG_DIR_CATEGORY}"
fi
BUCKET_AND_PATH=${FULL_S3_PATH#s3a://}
ALIAS_NAME="minio_${SPARK_JOB_LOG_DIR_CATEGORY}"

echo "Using alias: $ALIAS_NAME for S3 path: $BUCKET_AND_PATH"

# Check if alias already exists, create if it doesn't
if ! mc alias list | grep -q "^${ALIAS_NAME}"; then
    echo "Creating new alias: $ALIAS_NAME"
    mc alias set $ALIAS_NAME $MINIO_URL $MINIO_LOG_USER_ACCESS_KEY $MINIO_LOG_USER_SECRET_KEY
else
    echo "Alias $ALIAS_NAME already exists, reusing it"
fi

# Ensure the directory path exists by creating a dummy file
echo "dummy" | mc pipe $ALIAS_NAME/$BUCKET_AND_PATH/.dummy

echo "Directory structure ensured for: $BUCKET_AND_PATH"

mc alias rm $ALIAS_NAME

exit 0 
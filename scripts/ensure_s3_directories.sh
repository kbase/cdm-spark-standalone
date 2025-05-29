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
    echo "SPARK_JOB_LOG_DIR_CATEGORY not set, using SPARK_JOB_LOG_DIR as FULL_S3_PATH"
    FULL_S3_PATH="$SPARK_JOB_LOG_DIR"
else
    FULL_S3_PATH="${SPARK_JOB_LOG_DIR}/${SPARK_JOB_LOG_DIR_CATEGORY}"
fi
S3_URL_WITHOUT_PROTOCOL=${FULL_S3_PATH#s3a://}

ALIAS_NAME="minio_${SPARK_JOB_LOG_DIR_CATEGORY}"

echo "Using alias: $ALIAS_NAME for S3 path: $S3_URL_WITHOUT_PROTOCOL"

# Check if alias already exists, create if it doesn't
if ! mc alias list | grep -q "^${ALIAS_NAME}"; then
    echo "Creating new alias: $ALIAS_NAME"
    mc alias set $ALIAS_NAME $MINIO_URL $MINIO_LOG_USER_ACCESS_KEY $MINIO_LOG_USER_SECRET_KEY
else
    echo "Alias $ALIAS_NAME already exists, reusing it"
fi

# Ensure the directory path exists by creating a dummy file
echo "dummy" | mc pipe $ALIAS_NAME/$S3_URL_WITHOUT_PROTOCOL/.dummy

echo "Directory structure ensured for: $S3_URL_WITHOUT_PROTOCOL"

mc alias rm $ALIAS_NAME

exit 0 
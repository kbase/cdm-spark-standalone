#!/bin/bash

# This script sets up the Spark environment variables and configurations for Spark master, worker, and driver (Jupyter) nodes.

# Load Spark environment variables
source /opt/bitnami/scripts/spark-env.sh
if [ -z "$SPARK_CONF_FILE" ]; then
    echo "Error: unable to find SPARK_CONF_FILE path"
    exit 1
fi

# Redis configuration (optional)
# Set default values if not provided
: "${REDIS_HOST:=}"
: "${REDIS_PORT:=}"

# Warn if Redis is not configured but will continue execution
if [ -z "$REDIS_HOST" ] || [ -z "$REDIS_PORT" ]; then
    echo "Warning: Redis not configured (REDIS_HOST or REDIS_PORT not set). Redis caching will be disabled." >&2
fi

# Set Spark configurations

# Set default values if not provided by the environment
: "${MAX_EXECUTORS:=5}"              # Default dynamic allocation executors to 5 if not set
: "${EXECUTOR_CORES:=2}"             # Default executor cores to 2 if not set
: "${MAX_CORES_PER_APPLICATION:=10}" # Default maximum cores per application to 10 if not set
: "${DATANUCLEUS_AUTO_CREATE_TABLES:=true}" # Default DataNucleus auto create tables to true if not set
: "${DELTALAKE_WAREHOUSE_DIR:=s3a://cdm-lake/warehouse}" # Default DeltaLake warehouse directory

{
    # For detailed explanations and definitions of configuration options,
    # please refer to the official Spark documentation:
    # https://spark.apache.org/docs/latest/configuration.html

    # Set dynamic allocation configurations to allow parallel job executions
    echo "spark.dynamicAllocation.enabled true"
    echo "spark.dynamicAllocation.shuffleTracking.enabled true"
    echo "spark.dynamicAllocation.minExecutors 1"
    echo "spark.dynamicAllocation.initialExecutors 1"
    echo "spark.dynamicAllocation.maxExecutors $MAX_EXECUTORS"
    echo "spark.executor.cores $EXECUTOR_CORES"

    # Backlog timeouts for scaling up
    echo "spark.dynamicAllocation.schedulerBacklogTimeout 1s"            # Fast initial scale-up
    echo "spark.dynamicAllocation.sustainedSchedulerBacklogTimeout 10s"  # Conservative follow-up

    # Executor idle timeouts for scaling down
    echo "spark.dynamicAllocation.executorIdleTimeout 300s"
    echo "spark.dynamicAllocation.cachedExecutorIdleTimeout 1800s"

    # Decommissioning
    echo "spark.decommission.enabled true"
    echo "spark.storage.decommission.rddBlocks.enabled true"

    # Fair scheduling - within the same application
    echo "spark.scheduler.mode FAIR"

    # Set maximum cores configuration for an application
    echo "spark.cores.max ${MAX_CORES_PER_APPLICATION}"

    # Set spark.driver.host if SPARK_DRIVER_HOST is set
    if [ -n "$SPARK_DRIVER_HOST" ]; then
        echo "spark.driver.host $SPARK_DRIVER_HOST"
    fi
    
    # Redis configuration for caching (if enabled)
    if [ -n "$REDIS_HOST" ] && [ -n "$REDIS_PORT" ]; then
        echo "spark.redis.host ${REDIS_HOST}"
        echo "spark.redis.port ${REDIS_PORT}"
    fi
} >> "$SPARK_CONF_FILE"

# Config hive-site.xml for Hive support
sed -e "s|{{POSTGRES_URL}}|${POSTGRES_URL}|g" \
    -e "s|{{POSTGRES_DB}}|${POSTGRES_DB}|g" \
    -e "s|{{POSTGRES_USER}}|${POSTGRES_USER}|g" \
    -e "s|{{POSTGRES_PASSWORD}}|${POSTGRES_PASSWORD}|g" \
    -e "s|{{DATANUCLEUS_AUTO_CREATE_TABLES}}|${DATANUCLEUS_AUTO_CREATE_TABLES}|g" \
    -e "s|{{DELTALAKE_WAREHOUSE_DIR}}|${DELTALAKE_WAREHOUSE_DIR}|g" \
    /opt/config/hive-site-template.xml > "$SPARK_HOME"/conf/hive-site.xml
# KBase Spark Standalone Deployment

This repository contains the Dockerfile and associated configurations for deploying
Apache Spark in a standalone mode using Docker.

## Getting Started

1. Clone the repository

    ```bash
    git clone git@github.com:kbase/cdm-spark-standalone.git
    cd cdm-spark-standalone
    ```

2. Build the Docker image

    ```bash
    docker compose up -d --build
    ```

3. Access the Spark UI:
- Spark Master: http://localhost:8090
- Spark Worker 1: http://localhost:8081
- Spark Worker 2: http://localhost:8082

## Testing the Spark Cluster

To test the cluster is working:

1. Start a shell in the spark-user container:
    ```bash
    docker compose exec -it spark-user bash
    ```

2. Submit a test job:
    ```
    spark_user@d30c26e91ae0:/opt/bitnami/spark$ bin/spark-submit --master $SPARK_MASTER_URL --deploy-mode client examples/src/main/python/pi.py 10
    ```

You should see a line like

```
Pi is roughly 3.138040
```

in the output.

## Using Redis for Caching

1. Start a shell in the spark-user container:
   ```bash
   docker compose exec -it spark-user bash
   ```

2. Run the example:
   ```bash
   spark-submit /app/redis_container_script.py
   ```

### Verifying Cache in Redis

1. Start a shell in the Redis container:
   ```bash
   docker compose exec -it redis bash
   ```

2. Start the Redis CLI:
   ```bash
   redis-cli
   ```

3. List all keys for your cached table:
   ```bash
   keys people:*
   ```

4. View the contents of a specific key (replace the key with one from the previous command):
   ```bash
   hgetall people:d6d606a747ae40368fc7fdae784b835b
   ```
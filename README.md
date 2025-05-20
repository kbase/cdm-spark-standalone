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

2. Create a Python file with the example code:
   ```bash
   cat > redis_example.py << 'EOF'
   from pyspark.sql import SparkSession
   from pyspark.sql.types import StructType, StructField, StringType, IntegerType

   # Create a SparkSession with Redis configuration by default
   spark = SparkSession.builder \
       .appName("SparkRedisExample") \
       .master("spark://spark-master:7077") \
       .getOrCreate()

   sc = spark.sparkContext
   sc.setLogLevel("WARN") 

   # Create example data
   schema = StructType([
       StructField("name", StringType(), False),
       StructField("age", IntegerType(), False)
   ])
   person_data = [("John", 30), ("Peter", 45)]
   df = spark.createDataFrame(person_data, schema=schema)

   print("Original DataFrame:")
   df.show()

   # Cache data in Redis
   print("Caching data in Redis...")
   df.write.format("org.apache.spark.sql.redis") \
       .option("table", "people") \
       .mode("overwrite") \
       .save()

   # Read data from Redis cache
   print("Reading data from Redis cache:")
   cached_df = spark.read.format("org.apache.spark.sql.redis") \
       .option("table", "people") \
       .load()
   cached_df.show()

   spark.stop()
   EOF
   ```

3. Run the example:
   ```bash
   bin/spark-submit redis_example.py
   ```

### Verifying Cache in Redis

1. Connect to the Redis container:
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
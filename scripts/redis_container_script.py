"""
This script is used to test the Redis container.
It creates a SparkSession and connects to the Redis container.
It then creates a DataFrame and caches it in Redis.
It then reads the data from Redis and displays it.
"""

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
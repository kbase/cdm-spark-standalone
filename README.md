# KBase Spark Standalone Deployment

This repository contains the Dockerfile and associated configurations for deploying
Apache Spark in a standalone mode using Docker.

## Test

To test the cluster is working:

```
$ docker compose up -d --build
$ docker compose exec -it spark-user bash
spark_user@d30c26e91ae0:/opt/bitnami/spark$ bin/spark-submit --master $SPARK_MASTER_URL --deploy-mode client examples/src/main/python/pi.py 10
```

You should see a line like

```
Pi is roughly 3.138040
```

in the output.


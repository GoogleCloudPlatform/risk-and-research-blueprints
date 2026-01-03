# Create Agent Container and Setup

## Overview

This will create the HTC Agent for testing purposes as well as a chosen example.

## Setup environment

### Choose your region

```sh
test -n "$REGION" || read -e -p "Enter region: " REGION
```

## Building and publishing the container

*NOTE*: You may be prompted to enable some APIs during these steps.

### Create the docker repository

```sh
gcloud artifacts repositories create --location "${REGION}" --repository-format=DOCKER htcexample
REPO="${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/htcexample"
```

### Build the agent and push the container

```sh
docker build -t ${REPO}/htcagent:latest agent
docker push ${REPO}/htcagent:latest
```

### Build the example workload container

```sh
docker build -t ${REPO}/htcexample:latest examples/htcexample
docker push ${REPO}/htcexample:latest
```

## Generate test data

### Create the staging bucket

```sh
gcloud storage buckets create --location ${REGION} gs://${GOOGLE_CLOUD_PROJECT}-data/
```

### Generate example data

Generate 10,000 lines of test data into a GZIP'd JSONL file in GCS.

```sh
examples/htcexample/generate_test_data.py --count 10000 - | gzip | gcloud storage cp - gs://${GOOGLE_CLOUD_PROJECT}-data/test_data.jsonl.gz
gcloud storage ls --long --readable-sizes gs://${GOOGLE_CLOUD_PROJECT}-data/test_data.jsonl.gz
```

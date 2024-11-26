
# gRPC Tutorial

## Overview

This will deploy a gRPC-based Go simulator to Cloud Run and call into the service locally.

This assumes that the Setup tutorial has been executed, including setting
the REGION and REPO environment variables.

## Deploying to Cloud Run

### Deploy

```sh
gcloud run deploy \
	htcexample-grpc \
	--region="${REGION}" \
	--project="${GOOGLE_CLOUD_PROJECT}" \
  --port=8080 \
	--image=${REPO}/htcexample:latest \
	--args=--p,8080 \
	--use-http2 \
	--cpu=1000m \
	--memory=1Gi
```

### Capture the URL

```sh
GRPC_URL=$(gcloud run services describe htcexample-grpc --region ${REGION} --format="get(status.url)")
echo URL: ${GRPC_URL}
```

## Test the container with gRPC

### Launch the Cloud Run Proxy

*NOTE*: This needs to be in the background to act as a proxy.

```sh
cloud-run-proxy -host ${GRPC_URL} -http2 -token "$(gcloud auth print-identity-token)" &
```

### Run the container on the host network against the proxy

This will run, as quickly as possible, gRPC requests in a single thread.

--max_batch can increase the number of concurrent requests and --rate can decrease
the rate at which requests are issued.

```sh
docker run \
  --network host '
  ${REPO}/htcagent:latest test grpc \
    --endpoint http://localhost:8080/ \
    --source gs://${GOOGLE_CLOUD_PROJECT}-data/test_data.jsonl.gz \
    --serivce main.QuantService \
    --method RunLibrary
```

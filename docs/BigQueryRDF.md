
# BigQuery Remote Function

## Overview

This will create a BigQuery RDF function calling Go-based code and use Protobof for the encoding/decoding of messages. (JSON within the BigQuery context)

This assumes that the Setup tutorial has been executed, including setting
the REGION and REPO environment variables.

## Deploying to Cloud Run

### Deploy

```sh
gcloud run deploy \
        htcexample-rdf \
        --region="${REGION}" \
        --project="${GOOGLE_CLOUD_PROJECT}" \
        --concurrency=2 \
        --no-allow-unauthenticated \
        --container=workload \
        --image=${REPO}/htcexample:latest \
        --cpu=1000m \
        --memory=1Gi \
        --container=ingress \
        --image=${REPO}/htcagent:latest \
        --port=8080 \
        --args=agent,rdf,--timeout,30s,--endpoint,http://localhost:2002/,--method,RunLibrary,--service,main.QuantService \
        --no-use-http2
```

### Fetch the URL from the deployed Cloud Run

```sh
URL_RDF=$(gcloud run services describe htcexample-rdf --region ${REGION} --format="get(status.url)")
echo "URL deployed: ${URL_RDF}"
```

## Create the BigQuery resources

### Enable the BigQuery API

```sh
gcloud services enable bigquery.googleapis.com
```

### Create the BigQuery dataset

```sh
bq mk --location ${REGION} --project_id ${GOOGLE_CLOUD_PROJECT} test_rdf
```

### Create the BigQuery connection

```sh
bq mk --connection \
  --connection_type=CLOUD_RESOURCE \
  --location=${REGION} \
  --display_name='HTC Example' \
  htcexampleconn
```

### Get the BigQuery Service Account associated with the BigQuery Connection

```sh
SERVICE_ACCOUNT=$(bq show --headless=true --format=json --connection --location=${REGION} htcexampleconn | jq -r .cloudResource.serviceAccountId)
echo "Service account is ${SERVICE_ACCOUNT}"
```

### Assign roles/run.invoker permission to the BigQuery Service Account

```sh
gcloud run services add-iam-policy-binding --region=${REGION} htcexample-rdf --member=serviceAccount:${SERVICE_ACCOUNT} --role=roles/run.invoker
```

*NOTE:*: You may have to wait up to 60 seconds for permissions to propagate. Proceed to the next steps, but when it comes to the trial query it might not work right away.

## Create the BigQuery RDF function

### Generate the BigQuery query for creating the routine

*NOTE*: For tuning, the max_batching_rows is important. This is the number of tasks that can be dispatched in a single HTTP request. When the tasks are tiny and fast, then this should be a larger number. When the tasks are larger (so more data) or -- more importantly -- take a long time to execute, this number should be smaller to distribute the tasks better across Cloud Run workers.

```sh
BQ_PROJECT=$(printf "\x60${GOOGLE_CLOUD_PROJECT}\x60")
BQ_REGION=$(printf "\x60${REGION}\x60")
ROUTINE_QUERY=$(echo "" \
"CREATE OR REPLACE FUNCTION ${BQ_PROJECT}.test_rdf.htcexample(quanttask JSON)\n" \
"  RETURNS JSON\n" \
"REMOTE WITH CONNECTION ${BQ_PROJECT}.${BQ_REGION}.htcexampleconn\n" \
"OPTIONS (\n" \
"  endpoint = '${URL_RDF}',\n" \
"   max_batching_rows = 50\n" \
");\n")

echo "Routine Query:"
echo -e "${ROUTINE_QUERY}"
```

### Run the BigQuery Query

NOTE: This can be done in the [BigQuery console](https://console.cloud.google.com/bigquery) as well.

```sh
echo -e "${ROUTINE_QUERY}" | bq query --nouse_legacy_sql --project_id ${GOOGLE_CLOUD_PROJECT}
```

## Trial run

*NOTE*: You may have to wait up to 60 seconds for permissions to propagate.

This should be done in the [BigQuery console](https://console.cloud.google.com/bigquery). Please also open the metrics (and logs) in the [Cloud Run console](https://console.cloud.google.com/run) for htcexample-rdf.

### Trial run

```sql
SELECT
  test_rdf.htcexample(req) as response
FROM UNNEST([
  TO_JSON(STRUCT(
    STRUCT(
      1 AS id,
      4000000 AS min_micrdos,
      100 AS result_size
    ) AS initialTask,
    STRUCT(
      1 AS id,
      100000 AS min_micros,
      100 AS result_size
    ) AS task
  ))]) AS req;
```

## More complex example

This is a more complex example where we start to stress the RDF function. We can generate lots of data to send, process lots of data back, and scale up the number of tasks that are running (& compute time per task).

### SQL

Increase the min_micros, GENERATE_ARRAY length, and result_size as you want to stress the data and compute.

```sql
WITH
  Inputs AS (
    SELECT
      STRUCT(
        STRUCT(
          init_id AS id,
          1500000 AS min_micros
        ) AS initialTask,
        STRUCT(
          i AS id,

          -- Result size expected back
          1024 AS result_size,

          -- Number of milliseconds each task takes
          100000 AS min_micros,
          100000 AS max_micros,

          -- Empty string payload for data
          CAST(REPEAT(' ', 1024) AS BYTES) AS payload

        ) AS task
      ) AS req
    FROM
      -- Join a unique identifier for the initialization
      UNNEST([CAST(RAND() * 1000000 AS INT64)]) AS init_id

      -- Number of requests to send in
      CROSS JOIN UNNEST(GENERATE_ARRAY(1, 10)) AS i

  ),
  Calculations AS (
    SELECT
      req,
      test_rdf.htcexample(TO_JSON(req)) AS response
    FROM
      Inputs
  )
SELECT

  -- Initial task timings
  SUM(IF(JSON_QUERY(response, '$.init.total_micros') IS NULL, 0, 1)) AS initial_tasks,
  IFNULL(SUM(LAX_INT64(JSON_QUERY(response, '$.init.total_micros'))), 0) AS initial_time,

  -- Task timings
  COUNT(*) AS tasks,
  SUM(LAX_INT64(JSON_QUERY(response, '$.task.total_micros'))) AS task_time,

  -- Task bytes shuffled
  SUM(LENGTH(req.task.payload)) AS task_sent_bytes_payload,
  SUM(LENGTH(JSON_VALUE(response, '$.task.payload'))) AS task_recv_bytes_payload

FROM
  Calculations
```

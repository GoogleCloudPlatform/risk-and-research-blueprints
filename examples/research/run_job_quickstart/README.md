# Cloud Run Python Jobs made easy

TODO: Switch gsutil to gcloud storage
TODO: Try out in a fresh project.
TODO: Add more documentation, particularly around the code.

This walk-through progressively runs Polars-based task locally, in a container, and in
parallel Cloud Run jobs. This can scale up to many parallel jobs and can be embedded
within a larger workflow.

## Setup environment

Install uv
```sh
pip install --upgrade uv
export PATH=$PATH:$HOME/.local/bin
```

## Run local Polars Python with local files

```sh
cat sample.py
```

```sh
cat input.csv
```

```sh
./sample.py input.csv output-local.csv 100
```

```sh
cat output-local.csv
```

## Run local Polars Python in a container

```sh
docker build . -t sample
```

```sh
docker run -v ${PWD}:/data sample /data/input.csv /data/output-docker.csv 101
```

```sh
cat output-docker.csv
```

## Stage with Cloud Storage

Set the region.

```sh
read -p "Region? " REGION
export REGION=${REGION:-us-central1}
echo Using region $REGION
```

Create the bucket

```sh
export BUCKET=${GOOGLE_CLOUD_PROJECT}-${REGION}-$(printf "%04x" $RANDOM)
gsutil mb -l ${REGION} gs://${BUCKET}/
```

```sh
gsutil cp input.csv gs://${BUCKET}/
```

## Run with Cloud Storage

### Run local with Cloud Storage

```sh
./sample.py gs://${BUCKET}/input.csv gs://${BUCKET}/output-local.csv 102
gsutil cat gs://${BUCKET}/output-local.csv
```

### Run local container with Cloud Storage

```sh
docker run -v ${HOME}/.config/gcloud:/root/.config/gcloud sample gs://${BUCKET}/input.csv gs://${BUCKET}/output-local-docker.csv 103
gsutil cat gs://${BUCKET}/output-local-docker.csv
```

## Run as a Cloud Run Job

### Create the Artifact Registry

```sh
gcloud artifacts repositories create --repository-format=DOCKER --location ${REGION} job-sample
export REPO=${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/job-sample
```

### Push the container to the Artifact Registry

```sh
docker tag sample ${REPO}/sample:latest
docker push ${REPO}/sample:latest
```

### Create the service account for the runtime

Grant access as an object user to the bucket.

```sh
gcloud iam service-accounts create sample-run
gcloud storage buckets add-iam-policy-binding gs://${BUCKET} --member=serviceAccount:sample-run@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role=roles/storage.objectUser
```

### Create and run the job

Create the job.

```sh
gcloud run jobs create sample-job --service-account=sample-run@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --image ${REPO}/sample:latest --region ${REGION}
```

Run the job.

```sh
gcloud run jobs execute sample-job --wait --region ${REGION} --args=gs://${BUCKET}/input.csv,gs://${BUCKET}/output-j1.csv,104
```

See the output.

```sh
gsutil cat gs://${BUCKET}/output-j1.csv
```

## Launch with Python

Setup the JOB_ID

```sh
export JOB_ID=projects/${GOOGLE_CLOUD_PROJECT}/locations/${REGION}/jobs/sample-job
```

Launch four jobs directly against the bucket data.

```sh
./launch.py ${JOB_ID} gs://${BUCKET}/input.csv gs://${BUCKET}/output-j2-MULTIPLIER.csv 110 111 112 113
```

Launch ten jobs directly with staging of local data to and from the GCS bucket.

```sh
gcloud auth login --update-adc
```

```sh
./launch-gcs.py ${BUCKET} ${JOB_ID} input.csv output-j3-MULTIPLIER.csv $(seq 121 130)
```



Steps:
* Add add-on to cluster
* Get credentials and run `kubectl apply -f cluster.yaml`
* `build.sh`
* Build and copy loadtest into local directory
* `uvx --python 3.12 ray job submit --runtime-env-json='{"pip": ["grpcio-tools","apache-beam[gcp]>=2.63.0"]}' --working-dir . python ray_loadtest.py`

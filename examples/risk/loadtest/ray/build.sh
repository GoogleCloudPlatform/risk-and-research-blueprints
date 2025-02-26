#!/bin/bash

ROOT="$(dirname $0)"

uvx --python 3.12 --from="grpcio-tools==1.65.5" python3 -m grpc_tools.protoc \
  -I"${ROOT}/../src" \
  --grpc_python_out="${ROOT}" \
  "${ROOT}/../src/service.proto"

uvx --python 3.12 --from="grpcio-tools==1.65.5" python3 -m grpc_tools.protoc \
  -I"${ROOT}/../src" \
  --python_out="${ROOT}" \
  "${ROOT}/../src/request.proto" \
  "${ROOT}/../src/response.proto"


#!/bin/bash

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Default values for environment variables
MOUNT_PATH=${MOUNT_PATH:-"/data"}
CONFIG_PATH=${CONFIG_PATH:-"/etc/fio/fio.conf"}

cleanup() {
    echo "Cleaning up FIO files..."
    # Kill fio process if it's running
    pkill fio || echo "pkill fio returned non-zero exit code (likely no fio process found)"
    # Give fio a moment to clean up
    sleep 2
    exit 0
}

trap cleanup SIGTERM SIGINT SIGKILL

# Function to check if path is mounted
check_mount() {
    local path=$1
    local max_attempts=30
    local attempt=1

    echo "Checking mount point: $path"

    while ! mountpoint -q "${path}"; do
        if [ $attempt -ge $max_attempts ]; then
            echo "Mount point ${path} not ready after ${max_attempts} attempts. Exiting."
            exit 1
        fi
        echo "Waiting for ${path} to be mounted... (attempt $attempt/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done

    echo "Mount point ${path} is ready"
}

# Function to validate FIO config
validate_fio_config() {
    if [ ! -f "${CONFIG_PATH}" ]; then
        echo "Error: FIO config file ${CONFIG_PATH} not found"
        exit 1
    fi
}

# Main execution
echo "Starting FIO test runner"
echo "Mount path: ${MOUNT_PATH}"
echo "Config file: ${CONFIG_PATH}"

# Run checks
check_mount "${MOUNT_PATH}"
validate_fio_config

# Run FIO
echo "Starting FIO benchmark..."
exec fio --directory="${MOUNT_PATH}" \
    --output-format=json+ \
    "${CONFIG_PATH}" \
    | jq -c

# Check FIO exit status
FIO_STATUS=$?
if [ $FIO_STATUS -ne 0 ]; then
    echo "FIO failed with exit status: ${FIO_STATUS}"
    exit $FIO_STATUS
fi

echo "FIO benchmark completed successfully"

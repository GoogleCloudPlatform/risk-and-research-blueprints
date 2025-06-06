#!/usr/bin/env -S uv --quiet run --script

# /// script
# dependencies = [
#     "google-cloud-run>=0.10.17",
# ]
# ///


import argparse
import asyncio
import sys

from google.cloud import run_v2


PROJECT_ID = 'fsi-scratch-a'
JOB_ID = 'test-job'
LOCATION = 'europe-west1'


async def launch(client, name, args):
    operation = await client.run_job(request=run_v2.RunJobRequest(
        name=name,
        overrides=run_v2.RunJobRequest.Overrides(
            container_overrides=[
                run_v2.RunJobRequest.Overrides.ContainerOverride(
                    args=args,
                ),
            ],
        ),
    ))
    await operation.result()


async def run_process(infile, job_id, outfile, multipliers):

    # Run jobs and capture outputs
    jobs_client = run_v2.JobsAsyncClient()

    async def launch(m):
        await launch(
            jobs_client,
            job_id,
            [infile, outfile, str(m)],
        )

    # Run them all
    await asyncio.gather(*[launch_and_download(m) for m in multipliers])


def main(args):
    parser = argparse.ArgumentParser(prog='test gcs-based objects')
    parser.add_argument('job_id', type=str)
    parser.add_argument('infile', type=str)
    parser.add_argument('outfile', type=str)
    parser.add_argument('multipliers', type=int, nargs='+')

    args = parser.parse_args()

    asyncio.run(run_process(
        args.job_id, args.infile, args.outfile, args.multipliers))


if __name__ == "__main__":
    main(sys.argv[1:])

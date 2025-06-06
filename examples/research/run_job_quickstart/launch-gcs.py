#!/usr/bin/env -S uv --quiet run --script

# /// script
# dependencies = [
#     "google-cloud-run>=0.10.17",
#     "google-aio-storage>=9.4.0",
# ]
# ///


import argparse
import asyncio
import sys

from google.cloud import run_v2
from google.aio.storage import Storage
from uuid import uuid4
from pathlib import Path


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


async def run_process(bucket, job_id, infile, outfile, multipliers):
    async with Storage() as client:

        # Upload input
        remote_infile = f'{uuid4()}{''.join(Path(infile).suffixes)}'
        await (client.bucket(bucket)
                     .blob(remote_infile)
                     .upload_from_filename(infile))

        # Run jobs and capture outputs
        jobs_client = run_v2.JobsAsyncClient()
        remote_outfile = f'{uuid4()}{''.join(Path(outfile).suffixes)}'

        async def launch_and_download(m):
            new_remote_outfile = remote_outfile.replace('MULTIPLIER', str(m))

            await launch(
                jobs_client,
                job_id,
                [remote_infile, new_remote_outfile, str(m)],
            )

            await (client.bucket(bucket)
                         .blob(new_remote_outfile)
                         .download_to_filename(
                             outfile.replace('MULTIPLIER', str(m))))

        # Run them all
        await asyncio.gather(*[launch_and_download(m) for m in multipliers])


def main(args):
    parser = argparse.ArgumentParser(prog='test with upload/download')
    parser.add_argument('bucket', type=str)
    parser.add_argument('job_id', type=str)
    parser.add_argument('infile', type=str)
    parser.add_argument('outfile', type=str)
    parser.add_argument('multipliers', type=int, nargs='+')

    args = parser.parse_args()

    asyncio.run(run_process(
        args.bucket, args.job_id, args.infile, args.outfile, args.multipliers))


if __name__ == "__main__":
    main(sys.argv[1:])

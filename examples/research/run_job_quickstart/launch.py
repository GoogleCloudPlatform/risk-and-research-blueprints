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


async def run_process(
        job_id,
        infile,
        outfile,
        multipliers):

    jobs_client = run_v2.JobsAsyncClient()

    async def launch(m):
        m_outfile = outfile.replace('MULTIPLIER', str(m))

        print(f'Launching job {m}')
        operation = await jobs_client.run_job(request=run_v2.RunJobRequest(
            name=job_id,
            overrides=run_v2.RunJobRequest.Overrides(
                container_overrides=[
                    run_v2.RunJobRequest.Overrides.ContainerOverride(
                        args=[
                            infile,
                            m_outfile,
                            str(m)],
                    ),
                ],
            ),
        ))
        await operation.result()

    # Run them all
    await asyncio.gather(*[launch(m) for m in multipliers])


def main(args):
    parser = argparse.ArgumentParser(prog='launch sample')
    parser.add_argument('job_id', type=str)
    parser.add_argument('infile', type=str)
    parser.add_argument('outfile', type=str)
    parser.add_argument('multipliers', type=int, nargs='+')

    args = parser.parse_args()

    asyncio.run(run_process(
        job_id=args.job_id,
        infile=args.infile,
        outfile=args.outfile,
        multipliers=args.multipliers))


if __name__ == "__main__":
    main(sys.argv[1:])

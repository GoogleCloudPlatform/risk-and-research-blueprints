#!/usr/bin/env -S uv --quiet run --script

# /// script
# dependencies = [
#     "polars>=1.26.0",
#     "gcsfs>=2025.3.2",
# ]
# ///


import argparse
import polars as pl
import sys


def process(df, multiplier):
    df = df.with_columns(
        pl.lit(multiplier).alias("multiplier"),
        (pl.col("base") * multiplier).alias("result"),
    )
    return df


def main(args):
    parser = argparse.ArgumentParser(prog='test')
    parser.add_argument('infile', type=str)
    parser.add_argument('outfile', type=str)
    parser.add_argument('multiplier', type=int)

    args = parser.parse_args()

    df = pl.scan_csv(args.infile)
    df = process(df, args.multiplier)
    df = df.collect()
    df.write_csv(args.outfile)


if __name__ == "__main__":
    main(sys.argv[1:])

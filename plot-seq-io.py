#!/usr/bin/env python
# Create plots of IO performance based on ./seq-io script output
#
# The script takes a directory of json files describing the results
# of the test
from pathlib import Path
import json
from matplotlib.dates import DayLocator, DateFormatter
import matplotlib.pyplot as plt
import polars as pl
import sys
from typing import Sequence

USAGE = "Usage: ./plot-seq-io results_dir"
RESULTS_FILE_EXT = ".json"


def fatal(message: str):
    print(message, file=sys.stderr)
    sys.exit(1)


def exit_if_not_valid_dir(results_dir):
    if not results_dir.exists:
        fatal(f"Error: {results_dir} does not exist.")
    if not results_dir.is_dir():
        fatal(f"Error: {results_dir} exists but is not a directory.")


def discover_results(results_dir: Path) -> Sequence[Path]:
    return results_dir.glob(f"*{RESULTS_FILE_EXT}")


def load_results(results_files: Sequence[Path]):
    def append_to_lists(ts_list, speeds_list, json):
        ts_list.extend(json["times"][1:])
        speeds_list.extend(map(to_mbs, json["speeds"][1:]))

    def to_dataframe(ts_list, speeds_list):
        return pl.DataFrame(
            {"timestamp": ts_list, "speed_mbs": speeds_list}
        ).with_columns(pl.from_epoch("timestamp", time_unit="s"))

    write_ts, write_speeds = [], []
    read_ts, read_speeds = [], []
    for results_file in results_files:
        with open(results_file, "r") as fh:
            results = json.loads(fh.read())
        append_to_lists(write_ts, write_speeds, results["write"])
        append_to_lists(read_ts, read_speeds, results["read"])

    return to_dataframe(write_ts, write_speeds), to_dataframe(read_ts, read_speeds)


def to_mbs(s):
    parts = s.split()
    speed = float(parts[0])
    if "GB" in parts[1]:
        speed *= 1024
    return speed


def show_summary_statistics(write_speeds, read_speeds):
    print("IO Summary")
    print("----------")
    print()
    print("Write speed (MB/s):")
    print(f"  Min    : {write_speeds['speed_mbs'].min()}")
    print(f"  Max    : {write_speeds['speed_mbs'].max()}")
    print(f"  Mean   : {write_speeds['speed_mbs'].mean()}")
    print()
    print("Read speed (MB/s):")
    print(f"  Min    : {read_speeds['speed_mbs'].min()}")
    print(f"  Max    : {read_speeds['speed_mbs'].max()}")
    print(f"  Mean   : {read_speeds['speed_mbs'].mean()}")


def plot(write_speeds, read_speeds):
    fig, axes = plt.subplots(1, 2)
    axes[0].plot(write_speeds["timestamp"], write_speeds["speed_mbs"], "b.")
    axes[1].plot(read_speeds["timestamp"], read_speeds["speed_mbs"], "r.")

    for iotype, axes in (("write", axes[0]), ("read", axes[1])):
        axes.set_xlabel("Date")
        axes.set_ylabel(f"{iotype} speed (MB/s)")
        axes.xaxis.set_major_locator(DayLocator())
        axes.xaxis.set_major_formatter(DateFormatter("%Y-%m-%d"))
        axes.set_xticks(
            axes.get_xticks(), axes.get_xticklabels(), rotation=45, ha="right"
        )

    fig.tight_layout()
    plt.show()


def main():
    results_dir = Path(sys.argv[1]) if len(sys.argv) == 2 else fatal(USAGE)
    exit_if_not_valid_dir(results_dir)

    write_io, read_io = load_results(discover_results(results_dir))
    show_summary_statistics(write_io, read_io)
    plot(write_io, read_io)


main()

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
        ts_list.append(json["timestamp"])
        speeds_list.append(mean(json["speeds"]))

    def to_dataframe(ts_list, speeds_list):
        return pl.DataFrame(
            {"timestamp": ts_list, "average_speed_mbs": speeds_list}
        ).with_columns(pl.from_epoch("timestamp", time_unit="s"))

    write_ts, write_speeds = [], []
    read_ts, read_speeds = [], []
    for results_file in results_files:
        with open(results_file, "r") as fh:
            results = json.loads(fh.read())
        append_to_lists(write_ts, write_speeds, results["write"])
        append_to_lists(read_ts, read_speeds, results["read"])

    return to_dataframe(write_ts, write_speeds), to_dataframe(read_ts, read_speeds)


def mean(speeds_as_str: Sequence[str]) -> float:
    """Take a list of strings such as X.Y GB/s or XYZ MB/s, converts to MB/s and takes the mean"""

    def to_mbs(s):
        parts = s.split()
        speed = float(parts[0])
        if "GB" in parts[1]:
            speed *= 1024
        return speed

    num_speeds = len(speeds_as_str)
    sum = 0.0
    for speed in speeds_as_str:
        sum += to_mbs(speed)

    return sum / num_speeds


def plot(write_speeds, read_speeds):
    fig, axes = plt.subplots(1, 2)
    axes[0].plot(write_speeds["timestamp"], write_speeds["average_speed_mbs"], "b.")
    axes[1].plot(read_speeds["timestamp"], read_speeds["average_speed_mbs"], "r.")

    for iotype, axes in (("write", axes[0]), ("read", axes[1])):
        axes.set_xlabel("Date")
        axes.set_ylabel(f"Average {iotype} speed (MB/s)")
        axes.xaxis.set_major_locator(DayLocator())
        axes.xaxis.set_major_formatter(DateFormatter("%Y-%m-%d"))

    fig.tight_layout()
    plt.show()


def main():
    results_dir = Path(sys.argv[1]) if len(sys.argv) == 2 else fatal(USAGE)
    exit_if_not_valid_dir(results_dir)

    plot(*load_results(discover_results(results_dir)))


main()

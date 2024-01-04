# IO Performance Tests

This repository holds a script to test the IO performance of a filesystem using
`dd`.

It is aimed at running on a Linux system and has primarily been tested on
CentOS 7 and Rocky 8.

## Run the tests

The only required argument is the path to the temporary file used for the
read/write tests, e.g.

```sh
./seq-io.sh $HOME/tempfile
```

will perform the tests on a file called `tempfile` in the `$HOME` directory.
The temporary file is removed after the tests complete.

## Plotting the results

### Prerequisites

Install [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html#regular-installation)
for the current user as described in the Conda documentation.

Once installed open a shell and change to the directory of this
cloned repository and run:

```sh
conda env create -f ./condaenv -p ./condaenv
conda activate ./condaenv
```

After the first run of `conda env create ...` you only need to run the
`conda activate ./condaenv` command when opening a new shell.

### Plot

A single run of the script runs 5 loops of both write and read tests using `dd`
and prints the results to `stdout`.
To persist the results to a file redirect the output, e.g

```sh
./seq-io.sh $HOME/tempfile > results_dir/$(date +%y%d%m_%H%M%S).json
```

where `results_dir` is any directory that will hold the results (it must exist).
The `date` command names the file with a timestamp describing when the
script began executing and

To plot all of the results in `results_dir` run:

```sh
python ./plot-seq-io.py results_dir
```

## Inspecting disk hardware

To print a list of block devices with additional information run:

```sh
lsblk -o NAME,FSTYPE,LABEL,MOUNTPOINT,SIZE,MODEL
```

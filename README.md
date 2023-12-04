# IO Performance Tests

This repository holds a set of tools to test the IO performance of a filesystem.
It was created to explore possible performance issues with the Ceph filesystem
on an internal cloud where certain pieces of software that are IO heavy see
very inconsistent performance. It uses general tooling like `dd` to remove any
effects from the client software.

It is aimed at Linux but will work on macOS too.

## Run the tests

The main script `io-perf.sh` has 2 options:

- `-n`: The number of iterations of read & write tests to perform.
  The number applies separate to read & write. Default=5.
- `-o`: The output directory for the results file.
  Defaults to the current working directory.

The only required argument is the path to the temporary file used for the
read/write tests, e.g.

```sh
./io-perf -n 5 /tmp/tempfile
```

The temporary file is removed after the tests complete.

## Inspecting disk hardware

To print a list of block devices with additional information run:

```sh
lsblk -o NAME,FSTYPE,LABEL,MOUNTPOINT,SIZE,MODEL
```

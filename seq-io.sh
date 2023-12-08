#!/usr/bin/env /bin/bash
# Test sequential I/O with dd.
# Given a filepath runs read & write tests
niterations=5
iflags=nocache,fullblock
oflags=nocache

function dd_write() {
  dd if=/dev/zero of=$1 bs=1M count=1024 iflag=${iflags} oflag=${oflags} 2>&1 | tail -n 1 | cut -d, -f 3 | xargs
}

# Run a dd command to read from a file and write to /dev/null. Return just the speed string
function dd_read() {
  dd if=$1 of=/dev/null bs=1M count=1024 iflag=${iflags} oflag=${oflags} 2>&1 | tail -n 1 | cut -d, -f 3 | xargs
}

function run_write_tests() {
  results="{\"timestamp\": $(date +%s)"
  speeds=""
  for i in `seq 1 $niterations`; do
    sync >/dev/null 2>&1
    speed=$(dd_write $tempfile_path) 
    speeds="${speeds}${speeds:+,}\"$speed\""
  done
  results="$results, \"speeds\": [$speeds]}"
  echo $results
}

function run_read_tests() {
  results="{\"timestamp\": $(date +%s)"
  speeds=""
  for i in `seq 1 $niterations`; do
    speed=$(dd_read $tempfile_path)
    speeds="${speeds}${speeds:+,}\"$speed\""
  done
  results="$results, \"speeds\": [$speeds]}"
  echo $results
}


tempfile_path=$1
if [ -f "$tempfile_path" ]; then
  echo "File '${tempfile_path}' exists but this script would overwrite it."
  echo "Either remove the file or choose another path."
  exit 1
fi
json_writes=$(run_write_tests $tempfile_path $niterations)
# Run a read with nocache first to flush the cache
dd_read $tempfile_path >/dev/null 2>&1
json_reads=$(run_read_tests $tempfile_path $niterations)
echo "{\"write\": ${json_writes}, \"read\": ${json_reads}}"
rm -f $tempfile_path

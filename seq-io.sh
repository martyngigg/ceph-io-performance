#!/usr/bin/env /bin/bash
# Test sequential I/O with dd.
# Given a filepath runs read & write tests
niterations=5
iflags=nocache,fullblock
oflags=nocache
# In some unspecified dd version the output format changed and the speed column changed
# This test is not ideal but it was primarily running between centos 7 and rocky 8 so was
# good enough...
speed_column=4
if dd --version | head -n1 | grep 8.2 >/dev/null; then
  speed_column=3
fi

function dd_write() {
  dd if=/dev/zero of=$1 bs=1M count=1024 iflag=${iflags} oflag=${oflags} 2>&1 | tail -n 1 | cut -d, -f $speed_column | xargs
}

# Run a dd command to read from a file and write to /dev/null. Return just the speed string
function dd_read() {
  dd if=$1 of=/dev/null bs=1M count=1024 iflag=${iflags} oflag=${oflags} 2>&1 | tail -n 1 | cut -d, -f $speed_column | xargs
}

run_io_tests() {
  local iofunc=$1
  times=""
  speeds=""
  for i in `seq 1 $niterations`; do
    sync >/dev/null 2>&1
    speed=$($iofunc $tempfile_path)
    times="${times}${times:+,}$(date +%s)"
    speeds="${speeds}${speeds:+,}\"$speed\""
  done
  echo "{\"times\": [${times}], \"speeds\": [${speeds}]}"
}

run_write_tests() {
  echo $(run_io_tests dd_write)
}

run_read_tests() {
  echo $(run_io_tests dd_read)
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

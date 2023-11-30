#!/usr/bin/env bash
# Run IO tests with dd command
# It requires sudo for clearing VM caches
TEMPFILE_NAME=tempfile
NRUNS_DEFAULT=5

function drop_caches() {
  # macOS uses purge to drop caches
  if which purge >/dev/null 2>&1; then
    sync
    sudo purge
  elif which sysctl >/dev/null 2>&1; then
    sudo sysctl -w vm.drop_caches=3
  else
    echo "Unable to find sysctl or purge commands. Cannot purge fs caches"
    echo "Read results will not reflect actual IO speeds as a previous read will have buffered the data"
    exit 1
  fi
}

function run_io_tests() {
  local tempfile_path=$1
  local nruns=${2:-${NRUNS_DEFAULT}}

  run_write_tests $tempfile_path $nruns
  run_read_tests $tempfile_path $nruns
}

function run_write_tests() {
  local tempfile_path=$1
  local nruns=$2

  echo "Running write tests in $tempfile_path with $nruns iterations"
  for i in `seq 1 $nruns`; do
    sync
    dd if=/dev/zero of=$tempfile_path bs=1M count=1024
  done
}

function run_read_tests() {
  local tempfile_path=$1

  echo "Running read tests in $tempfile_path with $nruns iterations"
  for i in `seq 1 $nruns`; do
    drop_caches
    dd if=$tempfile_path of=/dev/null bs=1M count=1024
  done
}

function cleanup() {
  echo "Clearing sudo credentials"
  sudo -K

  echo "Removing temporary files"
  if [ -n "$TEMPFILE_NAME" ]; then
    test -f $HOME/$TEMPFILE_NAME && rm -f $HOME/$TEMPFILE_NAME
    test -f /tmp/$TEMPFILE_NAME && rm -f /tmp/$TEMPFILE_NAME
  fi
}

# Clean up temp files at exit
trap cleanup SIGHUP SIGINT SIGQUIT SIGABRT

# Authorise with sudo to run tests
echo "Sudo access required for dropping caches in read tests."
sudo -v
echo

# Argument processing
nruns=$1

# ---------- HOME ----------
run_io_tests $HOME/$TEMPFILE_NAME $nruns

# ---------- /tmp ----------
run_io_tests /tmp/$TEMPFILE_NAME $nruns

cleanup

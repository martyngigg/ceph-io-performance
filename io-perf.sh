#!/usr/bin/env bash
# Run IO tests with dd command
# It requires sudo for clearing VM caches
TEMPFILE_NAME=tempfile
NRUNS=5

function drop_caches() {
  # macOS uses purge to drop caches
  if [ -n "$(which purge)" ]; then
    sync
    sudo purge
  elif [ -n "$(which sysctl)" ]; then
    sudo sysctl -w vm.drop_caches=3
  else
    echo "Unable to find sysctl or purge commands. Cannot purge fs caches"
    echo "Read results will not reflect actual IO speeds as a previous read will have buffered the data"
    exit 1
  fi
}

function run_io_tests() {
  local tempfile_path=$1

  run_write_tests $tempfile_path
  run_read_tests $tempfile_path
}

function run_write_tests() {
  local tempfile_path=$1

  echo "Running write tests in $tempfile_path with $NRUNS iterations"
  for i in `seq 1 $NRUNS`; do
    sync
    dd if=/dev/zero of=$tempfile_path bs=1M count=1024
  done
}

function run_read_tests() {
  local tempfile_path=$1

  echo "Running read tests in $tempfile_path with $NRUNS iterations"
  for i in `seq 1 $NRUNS`; do
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

# ---------- HOME ----------
run_io_tests $HOME/$TEMPFILE_NAME

# ---------- /tmp ----------
run_io_tests /tmp/$TEMPFILE_NAME

cleanup

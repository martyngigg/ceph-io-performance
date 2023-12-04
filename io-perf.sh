#!/usr/bin/env bash
# Run IO tests with dd command
# It requires sudo for clearing VM caches
TEMPFILE_NAME=tempfile
NITERATIONS_DEFAULT=5


function drop_caches() {
  # macOS uses purge to drop caches
  if which purge >/dev/null 2>&1; then
    sync
    sudo purge
  elif which sysctl >/dev/null 2>&1; then
    sudo sysctl -w vm.drop_caches=3
  else
    info  "Unable to find sysctl or purge commands. Cannot purge fs caches"
    info  "Read results will not reflect actual IO speeds as a previous read will have buffered the data"
    exit 1
  fi
}

function run_write_tests() {
  local results_filename=$1
  local tempfile_path=$2
  local niterations=$3

  info  "# mode: write"
  for i in `seq 1 $niterations`; do
    sync >/dev/null 2>&1
    dd if=/dev/zero of=$tempfile_path bs=1M count=1024 2>&1
  done
}

function run_read_tests() {
  local tempfile_path=$1
  local tempfile_path=$2
  local niterations=$3

  info  "# mode: read"
  for i in `seq 1 $niterations`; do
    drop_caches >/dev/null 2>&1
    dd if=$tempfile_path of=/dev/null bs=1M count=1024 2>&1
  done
}

function write_header() {
  local tempfile_path=$1
  info  "# timestamp: $(date -Iseconds)"
  info  "# uname: $(uname -a)"
  info  "# path: ${tempfile_path}"
  info
}

function info() {
  echo $*
}

function fatal() {
  info  $*
  exit 1
}

function cleanup() {
  local tempfile_path="$1"
  info  "Clearing sudo credentials"
  sudo -K

  info  "Removing temporary file ${tempfile_path}"
  rm -f $tempfile_path
}

# Argument processing - pull out and set option flags
positional_args=()
niterations=$NITERATIONS_DEFAULT
output_dir="."

while [[ $# -gt 0 ]]; do
  case $1 in
    -n)
      niterations="$2"
      shift
      shift
      ;;
    -o)
      output_dir="$2"
      shift
      shift
      ;;
    -*|--*)
      fatal  "Unknown option $1"
      ;;
    *)
      positional_args+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# restore positional arguments as $1 $2 ...
set -- "${positional_args[@]}"

tempfile_path="$1"
test -z "${tempfile_path}" && fatal "Usage: io-perf [-n niterations -o output_dir] tempfile_path"

# Clean up temp files on exit
trap "cleanup ${tempfile_path}" EXIT SIGHUP SIGINT SIGQUIT SIGABRT

# Authorise with sudo to run tests
info  "Sudo access required for dropping caches in read tests."
sudo -v
info

# Run tests
results_filename=${output_dir}/$(date '+%Y%m%d%H%M').log
write_header $tempfile_path > $results_filename
run_write_tests $results_filename $tempfile_path $niterations >> $results_filename
run_read_tests $results_filename $tempfile_path $niterations >> $results_filename
info "Results written to $results_filename"

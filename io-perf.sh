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
    echo "Unable to find sysctl or purge commands. Cannot purge fs caches"
    echo "Read results will not reflect actual IO speeds as a previous read will have buffered the data"
    exit 1
  fi
}

function run_write_tests() {
  local results_filename=$1
  local tempfile_path=$2
  local niterations=$3

  echo "# mode: write"
  echo "# path: ${tempfile_path}"
  for i in `seq 1 $niterations`; do
    sync >/dev/null 2>&1
    dd if=/dev/zero of=$tempfile_path bs=1M count=1024 2>&1
  done
}

function run_read_tests() {
  local tempfile_path=$1
  local tempfile_path=$2
  local niterations=$3

  echo "# mode: read"
  echo "# path: ${tempfile_path}"
  for i in `seq 1 $niterations`; do
    drop_caches >/dev/null 2>&1
    dd if=$tempfile_path of=/dev/null bs=1M count=1024 2>&1
  done
}

function write_header() {
  echo "# timestamp: $(date -Iseconds)"
  echo "# uname: $(uname -a)"
  echo
}

function fatal() {
  echo $*
  exit 1
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

# Clean up temp files on exit
trap cleanup SIGHUP SIGINT SIGQUIT SIGABRT

# Argument processing - pull out option flags
positional_args=()
niterations=$NITERATIONS_DEFAULT

while [[ $# -gt 0 ]]; do
  case $1 in
    -niter)
      niterations="$2"
      shift
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      positional_args+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# restore positional arguments as $1 $2 ...
set -- "${positional_args[@]}"

results_filename=$1
shift
test -z "${results_filename}" && fatal "Usage: io-perf [-n niterations] results_filename path1 [path2 path3 ...]"

# Authorise with sudo to run tests
echo "Sudo access required for dropping caches in read tests."
sudo -v
echo

# Run tests
write_header $results_filename > $results_filename

for tempfile_path in $@; do
  run_write_tests $results_filename $tempfile_path $niterations >> $results_filename
  run_read_tests $results_filename $tempfile_path $niterations >> $results_filename
done

exit

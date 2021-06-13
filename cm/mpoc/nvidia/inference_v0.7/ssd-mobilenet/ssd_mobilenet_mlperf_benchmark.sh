#set -eo pipefail
set -x

## Variable declaration
MLPERF_INFERENCE_REPO="inference_results_v0.7"
INFERENCE_NVIDIA_PATH=~/inference_results_v0.7/closed/NVIDIA
MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build

## Checkout MLPerf Inference v0.7 repo from GitHub
[ ! -d "$MLPERF_INFERENCE_REPO" ] && git clone https://github.com/mlcommons/$MLPERF_INFERENCE_REPO.git ~/$MLPERF_INFERENCE_REPO

## Create NVIDIA MLPerf scratch path
[ ! -d "$MLPERF_SCRATCH_PATH" ] && mkdir -p $MLPERF_SCRATCH_PATH

## Check and Set NVIDIA Mlperf scratch path as envrionment variable
[[ ! -z `export | grep INFERENCE_NVIDIA_PATH` ]] && echo $INFERENCE_NVIDIA_PATH || export INFERENCE_NVIDIA_PATH=$INFERENCE_NVIDIA_PATH
[[ ! -z `export | grep MLPERF_SCRATCH_PATH` ]] && echo $MLPERF_SCRATCH_PATH || export MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build
export | grep $INFERENCE_NVIDIA_PATH

## Config mlperf benchmark scenario and Test mode default values
SCENARIO=$1
TEST_MODE=$2
if [ "$SCENARIO" == "" ]; then
    SCENARIO="SingleStream"
else
    SCENARIO=$SCENARIO
fi

if [ "$TEST_MODE" == "" ]; then
    TEST_MODE="PerformanceOnly"
else
    TEST_MODE=$TEST_MODE
fi

## Execute MLPerf Benchmark
cd $INFERENCE_NVIDIA_PATH
make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=$SCENARIO --test_mode=$TEST_MODE"

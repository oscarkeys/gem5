#!/bin/bash

# Update these for your system.
BENCHMARKS_PATH="/usr/local/src/gem5/benchmarks"
GEM5_PATH="/usr/local/src/gem5"

# The benchmark directory structure should be as follows:
# benchmarks/
#      |
#      |
#      --- automotive/
#      |       |
#      |       |
#      |       --- susan/
#      |
#      --- telecom/
#             |
#             |
#             --- CRC32/

help_function()
{
        echo ""
        echo "Usage  : $0 -a <architecture> -b <benchmark> -f <flags path>"
        echo "Example: $0 -a X86 -b susan -f ./flags"
        echo -e "\t-a The architecture for which to run the benchmark: X86 or ARM"
        echo -e "\t-b Benchmark to build and run: susan or CRC32"
        echo -e "\t-f Benchmark flags file path"
        exit 1 # Exit script after printing help
}

while getopts "a:b:f:" opt
do
        case "$opt" in
                a ) arch="$OPTARG"       ;;
                b ) bench="$OPTARG"      ;;
                f ) flags_path="$OPTARG" ;;
                ? ) help_function        ;;
        esac
done

if [ -z "$arch" ] || [ -z "$bench" ] || [ -z "$flags_path" ]; then
        echo "Empty parameters were found"
        help_function
fi

if [ "$arch" != "X86" ] && [ "$arch" != "ARM" ]; then
        echo "Invalid architecture provided: $arch"
        help_function
fi

if [ "$bench" != "susan" ] && [ "$bench" != "CRC32" ]; then
        echo "Invalid benchmark provided"
        help_function
fi

if [ ! -f "$flags_path" ]; then
        echo "Flags file does not exist"
        help_function
fi

echo "Starting ..."

gem5="$GEM5_PATH/build/$arch/gem5.opt"
gem5_config_script="$GEM5_PATH/configs/example/se.py"

if [ "$arch" == "X86" ]; then
        compiler=gcc
else
        compiler=arm-linux-gnueabi-gcc
fi

echo "Building $bench ..."

if [ "$bench" == "susan" ]; then
        make clean -C "$BENCHMARKS_PATH/automotive/susan"
        make CC="$compiler" -C "$BENCHMARKS_PATH/automotive/susan"

        binary="$BENCHMARKS_PATH/automotive/susan/susan"
        options="\"$BENCHMARKS_PATH/automotive/susan/input_large.pgm $BENCHMARKS_PATH/automotive/susan/output_large.smoothing.pgm -s\""
else
        make clean -C "$BENCHMARKS_PATH/telecomm/CRC32"
        make CC="$compiler" -C "$BENCHMARKS_PATH/telecomm/CRC32"

        binary="$BENCHMARKS_PATH/telecomm/CRC32/crc"
        options="\"$BENCHMARKS_PATH/telecomm/CRC32/../adpcm/data/large.pcm > output_large.txt\""
fi

echo "Running the benchmark ..."

echo "Running command:"

flags=$(echo $(cat $flags_path))
echo "$gem5 $gem5_config_script -c $binary -o $options $flags"
eval "$gem5 $gem5_config_script -c $binary -o $options $flags"
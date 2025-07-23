#!/bin/bash

iterations=20
modes=(1 2 3 4)
sizes=(1 2 5 8)

log_dir="./logs"
mkdir -p $log_dir

for mode in "${modes[@]}"
do
    for size in "${sizes[@]}"
    do
        echo "Running mode $mode with size $size"

        log_file="$log_dir/mode${mode}_size${size}.log"

        # empty before appending
        > $log_file

        for i in $(seq 1 $iterations)
        do
            timestamp=$(date "+%Y%m%d-%H%M%S")

            echo "Starting iteration $i for mode $mode with msg size $size at $timestamp" >> $log_file

            ./runTest.sh $log_file --mode $mode --send-size $size

            echo "Completed iteration $i for mode $mode with msg size $size at $timestamp" >> $log_file
            echo "----------------------------------------" >> $log_file
        done

        echo "All iterations for mode $mode with size $size completed. Logs saved to: $log_file"
    done
done

echo "All tests completed"
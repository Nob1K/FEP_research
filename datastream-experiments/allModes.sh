#!/bin/bash

iterations=100
modes=(1 2 3 4)

log_dir="./logs"
mkdir -p $log_dir

for mode in "${modes[@]}"
do
    echo "Running Mode $mode"
    
    log_file="$log_dir/mode${mode}.log"

    # empty before appending
    > $log_file

    for i in $(seq 1 $iterations)
    do
        timestamp=$(date "+%Y%m%d-%H%M%S")
        
        echo "Starting Iteration $i for Mode $mode at $timestamp" >> $log_file

        ./runTest.sh $log_file --mode $mode

        echo "Completed Iteration $i for Mode $mode at $timestamp" >> $log_file
        echo "----------------------------------------" >> $log_file
    done

    echo "All Iterations for Mode $mode completed. Logs saved to: $log_file"
done

echo "All tests completed."
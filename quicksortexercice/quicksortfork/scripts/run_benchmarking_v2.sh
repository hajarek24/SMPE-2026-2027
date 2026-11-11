#!/bin/bash
BIN=${1:-./src/parallelQuicksort}
OUT=data/$(hostname)_$(date +%F)
mkdir -p $OUT
lscpu > $OUT/lscpu.txt
FILE=$OUT/measurements_$(basename $BIN)_$(date +%H-%M).csv
echo "Size,Type,Time,Rep" > $FILE

# 30 repetitions of each size, in RANDOM order
for rep in $(seq 1 30); do
  for size in 100 1000 10000 50000 100000 200000 300000 400000 500000 700000 1000000 2000000 5000000; do
    echo "$size $rep"
  done
done | shuf | while read size rep; do
  $BIN $size | awk -v s=$size -v r=$rep '/quicksort took/ {print s","$1","$(NF-1)","r}'
done >> $FILE

echo "Results in $FILE"
#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Uso: $0 i"
  exit 1
fi

i=$1
fin=$((2 + i))

for (( idx=2; idx<=fin; idx++ )); do
  UE_IP="10.45.0.$idx"
  PORT=$((5200 + idx))
  echo "Lanzando UE con IP $UE_IP -> puerto $PORT"
  iperf3 -c 10.45.0.1 -u -b 100K -t 20 -p $PORT -B $UE_IP &
done

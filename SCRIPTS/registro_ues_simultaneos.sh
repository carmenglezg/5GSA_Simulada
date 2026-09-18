#!/bin/bash

# Verificar que se pasó un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <n>"
  echo "Lanza UEs desde 220 hasta 220 + n"
  exit 1
fi

# Argumento de entrada
n=$1

CONFIG_DIR="/home/carmen/UERANSIM/config/ues_simultaneos"
BUILD_DIR="/home/carmen/UERANSIM/build"

# Rango de UEs: desde 220 hasta 220 + n
start=220
end=$((start + n))

for ((i=start; i<end; i++)); do
  CONFIG_FILE="${CONFIG_DIR}/open5gs-ue_slice3_${i}.yaml"
  if [ -f "$CONFIG_FILE" ]; then
    echo "Lanzando UE con config $CONFIG_FILE"
    "${BUILD_DIR}/nr-ue" -c "$CONFIG_FILE" &
    sleep 5
  else
    echo "Archivo no encontrado: $CONFIG_FILE"
  fi
done

echo "Todos los UEs lanzados."

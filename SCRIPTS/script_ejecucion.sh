#!/bin/bash

# Directorio de UERANSIM
UERANSIM_DIR="/home/carmen/UERANSIM"

# Configuración de UEs
UE1_CONFIG="$UERANSIM_DIR/config/open5gs-ue1_caso1.yaml"
UE2_CONFIG="$UERANSIM_DIR/config/open5gs-ue2_caso1.yaml"

# IPs de test
UE1_TUN_IFACE="uesimtun0"  # Interfaz de UERANSIM UE1 (puede variar)
UE2_TUN_IFACE="uesimtun1"  # Interfaz de UERANSIM UE2 (puede variar)
DEST_IP="10.45.0.1"        # Destino para ping (puede cambiarse)

# Función para iniciar UEs
start_ues() {
    echo "Iniciando UE1 en Slice A (videollamada simulada)..."
    sudo $UERANSIM_DIR/build/nr-ue -c $UE1_CONFIG > ue1.log 2>&1 &
    UE1_PID=$!

    sleep 2

    echo "Iniciando UE2 en Slice B (navegación best-effort)..."
    sudo $UERANSIM_DIR/build/nr-ue -c $UE2_CONFIG > ue2.log 2>&1 &
    UE2_PID=$!
}

# Función para test de tráfico
run_tests() {
    echo "Esperando 10 segundos para registrar UEs..."
    sleep 10

    echo "Realizando prueba iperf3 en UE1 (Slice A)..."
    sudo iperf3 -c $DEST_IP -t 10 -B $(ip -4 addr show $UE1_TUN_IFACE | grep inet | awk '{print $2}' | cut -d/ -f1)

    echo "Realizando prueba de ping en UE2 (Slice B)..."
    sudo ping -I $UE2_TUN_IFACE $DEST_IP -c 10
}

# Función para limpiar
cleanup() {
    echo "Terminando procesos de UEs..."
    sudo kill $UE1_PID
    sudo kill $UE2_PID
    echo "Test finalizado."
}

# Ejecutar todo
start_ues
run_tests
cleanup


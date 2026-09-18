# 5G Network Slicing \& PCF QoS Optimization Testbed

This repository contains the configuration files, automation scripts, and experimental pipelines developed to evaluate **Policy Control Function (PCF)** policy enforcement and **Network Slicing** mechanisms within a 3GPP 5G Standalone (5G SA) environment.

The system architecture, addressing scheme, and experimental test scenarios implemented here are based on research:

> \*\*"Optimización del Network Slicing mediante políticas del PCF en redes 5G"\*\*  
> \*Author:\* Carmen González García  
> \*Advisor:\* Raúl Parada Medina  
---

## 1\. System Architecture \& Topology

The testbed decouples the 5G system logically across three distinct virtual machines (or nodes) running **Ubuntu 24.04.2 LTS** to balance system load and provide realistic end-to-end interface boundaries:

```
+-----------------------------------------------------------------------------------------------+
|                                      HOST SYSTEM                                              |
|                                                                                               |
|  +--------------------+         N2 (NGAP / SCTP)          +--------------------------------+  |
|  |   UERANSIM-gNB     |<--------------------------------->|           OPEN5GS              |  |
|  |  (192.168.56.111)  |                                   |       (192.168.56.112)         |  |
|  +---------+----------+         N3 (GTP-U / UDP)          |  NRF, AMF, SMF, PCF, UDM,     |  |
|            |           <--------------------------------->|  AUSF, UDR, MongoDB, WebUI     |  |
|            |                                              |  Interface: ogstun (10.45.0.1) |  |
|            | NR-Uu (Virtual Radio)                        +--------------------------------+  |
|            v                                                                                  |
|  +--------------------+                                                                       |
|  |   UERANSIM-UE      |                                                                       |
|  |  (192.168.56.113)  |                                                                       |
|  |  uesimtunX (DHCP)  |                                                                       |
|  +--------------------+                                                                       |
+-----------------------------------------------------------------------------------------------+
```

### Addressing \& Network Scheme

* **Management \& Local Subnet (`enp0s8`):** `192.168.56.0/24` (Host-Only adapter).
* **Internet Access (`enp0s3`):** NAT mode on the VM host.
* **Core Data Tunnel (`ogstun`):** `10.45.0.1/16` on the Open5GS machine.
* **UE Simulated Tunnels (`uesimtunX`):** Dynamically assigned IPs within `10.45.0.0/16` (e.g., `10.45.0.2`, `10.45.0.3`, ...).

\---

## 2\. Configured Network Slices \& Subscriptions

The core network defines three distinct Network Slices identified by S-NSSAI (SST / SD):

|Slice Name|Service Type (SST)|Slice Differentiator (SD)|Target Traffic|Configured PCF QoS Profile / Policy|
|-|:-:|:-:|-|-|
|**Slice A**|`1` (eMBB / High Priority)|`000001`|Critical / Real-Time (Video, Mission-Critical)|High priority, low latency, bandwidth guarantees, high ARP (no preemption target).|
|**Slice B**|`2` (URLLC / Standard)|`000002`|Best-effort / Browsing|Moderate priority, non-critical, subject to preemption under congestion.|
|**Slice C**|`3` (MIoT / Massive IoT)|`000003`|Massive Machine-Type Traffic|Low priority, high density of connected UEs, bandwidth throttled to 100 Kbps.|

\---

## 3\. Repository Structure \& File Mapping

The files in this repository correspond directly to the Open5GS configuration directory (`/etc/open5gs/`) and UERANSIM execution paths:

### Core Network Service Configurations (`/etc/open5gs/\*.yaml`)

* **`pcf.yaml`:** Configures session and traffic rules, QoS profiles (5QI, ARP priority level, preemption vulnerability/capability), and dynamic policy binding.
* **`amf.yaml`:** Binds the NGAP server to `192.168.56.112`, sets PLMN to `001-01`, and registers supported S-NSSAIs (`{sst: 1, sd: 000001}`, `{sst: 2, sd: 000002}`, `{sst: 3, sd: 000003}`).
* **`smf.yaml`:** Maps PDU sessions, IP pools (`10.45.0.0/16`), GTP-U termination endpoints (`192.168.56.112`), and assigns UPF instances to individual slices.
* **`upf.yaml`:** Manages user-plane routing, tunnel termination on `ogstun`, and packet forwarding rules.
* **`nssf.yaml`:** Implements Network Slice Selection assistance logic to route UE requests to appropriate network slices based on Requested NSSAI.
* **`nrf.yaml`:** Coordinates service registration and discovery among Core Network Functions.
* **`udm.yaml` \& `udr.yaml`:** Manages subscription profiles and slice authorizations against the local MongoDB instance.
* **`ausf.yaml`:** Handles 5G-AKA authentication sequences.
* **`bsf.yaml`, `scp.yaml`, `sepp1.yaml`, `sepp2.yaml`:** Supporting 5G Service-Based Architecture (SBA) infrastructure and inter-PLMN security proxies.
* **`hss.yaml`, `mme.yaml`, `pcrf.yaml`, `sgwc.yaml`, `sgwu.yaml`:** Backward-compatibility components for hybrid 4G/EPC interworking.

### Testbed \& Traffic Automation Scripts

* **`script\_testcaso1.sh`:** Automated benchmark for Scenario 1. It initiates two UEs simultaneously (UE1 in Slice A and UE2 in Slice B), waits 10s for registration and PDU session establishment, executes bi-directional throughput tests with `iperf3`, and measures latency and jitter using ICMP `ping`.
* **`script\_ejecucion.sh`:** Orchestrates scenario execution, handling UE lifecycle, background traffic generation via `iperf3`, log capture (`ue1.log`, `ue2.log`), and teardown.
* **`registro\_ues\_simultaneos.sh`:** Batch provisioning and connection script for mass-scale simulations. Launches `n` concurrent UERANSIM UEs starting from IMSI offset `220` up to `220 + n`, instantiating corresponding `uesimtunX` interfaces.
* **`lanzar\_iperf.sh`:** Generates multi-client UDP synthetic load across multiple UE tunnels concurrently. Directs flows to the core UPF endpoint (`10.45.0.1`) with configured bitrates (e.g., `-u -b 100K -t 20`) to assess slice saturation and isolation.

\---

## 4\. Prerequisites \& Installation

### Step 1: Open5GS Core Host (`192.168.56.112`)

1. Install MongoDB:

```bash
   sudo apt update \&\& sudo apt install -y gnupg curl
   curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
   echo "deb \[arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
   sudo apt update \&\& sudo apt install -y mongodb-org
   sudo systemctl enable --now mongod
   ```

2. Install Open5GS:

```bash
   sudo add-apt-repository ppa:open5gs/latest
   sudo apt update \&\& sudo apt install -y open5gs
   ```

3. Enable IP Forwarding and NAT (User Plane Data):

```bash
   sudo sysctl -w net.ipv4.ip\_forward=1
   sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 -o enp0s3 -j MASQUERADE
   sudo iptables -I INPUT -i ogstun -j ACCEPT
   sudo ufw disable
   ```

4. Copy the YAML files to `/etc/open5gs/`:

```bash
   sudo cp \*.yaml /etc/open5gs/
   sudo systemctl restart open5gs-\*
   ```

### Step 2: UERANSIM Hosts (`192.168.56.111` \& `192.168.56.113`)

On both the gNB and UE machines:

```bash
sudo apt update \&\& sudo apt install -y make gcc g++ libsctp-dev lksctp-tools iproute2 cmake iperf3
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
make
```

\---

## 5\. Execution Guide

### Phase 1: Start the Core \& Radio Network

1. On the **Open5GS Core** VM, verify that core services are active:

```bash
   sudo systemctl status open5gs-amfd open5gs-smfd open5gs-pcfd open5gs-upfd
   ```

2. On the **gNB** VM, start the simulated gNodeB:

```bash
   cd \~/UERANSIM
   sudo ./build/nr-gnb -c config/open5gs-gnb.yaml
   ```

   *Verify in the console output that the SCTP connection to AMF (`192.168.56.112`) is established and `NG Setup Response` is received.*

\---

### Phase 2: Run Scenario 1 (Isolated Slice QoS Validation)

On the **UE** VM, run the automated test:

```bash
chmod +x script\_testcaso1.sh
sudo ./script\_testcaso1.sh
```

The script will:

1. Launch `nr-ue` for Slice A (eMBB) and Slice B (Best-effort).
2. Verify tunnel creation (`uesimtun0` and `uesimtun1`).
3. Transmit 10 seconds of `iperf3` data traffic to destination `10.45.0.1`.
4. Run ICMP round-trip latency checks to confirm QoS prioritization.
5. Terminate the UE processes and log outputs.

\---

### Phase 3: Run Massive IoT \& Stress Testing (Scenario 5)

1. On the **Open5GS** VM, ensure test subscribers are loaded into MongoDB:

   * Access WebUI at `http://localhost:9999` (admin / 1423) or verify subscribers in MongoDB shell:

```bash
     mongosh open5gs --eval "db.subscribers.countDocuments()"
     ```

2. On the **UE** VM, launch `N` simultaneous simulated devices (e.g., 10 UEs):

```bash
   chmod +x registro\_ues\_simultaneos.sh lanzar\_iperf.sh
   sudo ./registro\_ues\_simultaneos.sh 10
   ```

3. Inspect generated tunnel devices:

```bash
   ip -br addr show | grep uesimtun
   ```

4. Inject concurrent multi-flow UDP traffic:

```bash
   ./lanzar\_iperf.sh 10
   ```

5. Monitor real-time traffic handling and policy enforcement via Wireshark on the Core VM (`ogstun` interface) and within Open5GS PCF logs:

```bash
   tail -f /var/log/open5gs/pcf.log
   ```

\---




# SCENARIOS & DATASETS

This directory contains example datasets for **ServerAlive**, used to simulate different network scanning scenarios.

These files are intended for testing, validation, and demonstration purposes.

---

## Components

- `targets.txt`  
  A list of example hosts including public services and local network nodes.

- `custom_ports.txt`  
  Predefined port sets grouped by common service categories (Web, Database, Admin, Legacy).

- `subnet_example.txt`  
  Example IP ranges for /24 network scanning simulation.

---

## Execution

These datasets can be used with ServerAlive as follows:

```bash
./server_alive.sh -f examples/targets.txt
./server_alive.sh -p "80,443,22" scanme.nmap.org
./server_alive.sh -s 192.168.1.0/24

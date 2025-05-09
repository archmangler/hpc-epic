#!/bin/bash

# HPC CLI Quickstart Script for NVIDIA-centric A.I Factory Clusters
# Automates basic checks and setup tasks for GPU, Lustre, and SLURM

echo "=== System Overview ==="
lscpu | grep 'Model name'
free -h
nvidia-smi --query-gpu=name,memory.total,temperature.gpu --format=csv,noheader

echo "=== Check GPU Topology ==="
nvidia-smi topo -m

echo "=== Check DCGM GPUs ==="
dcgmi discovery -l

echo "=== Lustre Filesystem Check ==="
mount | grep lustre
echo "Lustre DF:"
lfs df /mnt/lustre || echo "Lustre mount point /mnt/lustre not found"
lctl get_param obdfilter.*.stats 2>/dev/null | head -n 20

echo "=== SLURM Cluster Info ==="
sinfo
squeue -u $USER

echo "=== Check NVSwitch & Fabric Manager ==="
systemctl status nvidia-fabricmanager | grep Active

echo "=== RoCE/RDMA Device Status ==="
ibstat || echo "ibstat not available"
rdma link show || echo "rdma tools not available"

echo "=== Container GPU Availability ==="
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi || echo "Docker not set up for GPUs"

echo "=== Done ==="

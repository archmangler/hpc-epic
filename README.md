# An ongoing tale of HPC infrastructure management and implementation

This document assumes you have an HPC cluster something like the following:

- Delivers 512 H100s across 64 immersion-cooled nodes, 
- Backed by a 400Gbps InfiniBand fabric, 
- BlueField DPUs for offload and segmentation, and 
- A scratch + archival storage stack. 
- The estimated energy savings from immersion + DPU offload exceed 40%, meeting both performance and sustainability SLAs. 
- It’s scalable up to 2048 GPUs with no ToR re-architecture required.

# 📘 HPC CLI Guide for LLM Workloads

---

## 1. 🧱 HPC Components for LLM Workloads

| Layer                 | Components                                                                 |
|----------------------|----------------------------------------------------------------------------|
| OS & Drivers         | Rocky Linux, NVIDIA Drivers                                                |
| Container Runtime    | Docker, Podman, Singularity (Apptainer)                                    |
| GPU Compute Stack    | CUDA, cuDNN, TensorRT, NVIDIA Fabric Manager                               |
| Orchestration        | SLURM, Kubernetes (KubeFlow, Volcano), DCGM                                |
| Storage              | Lustre                                                                     |
| LLM Frameworks       | PyTorch, TensorFlow, DeepSpeed, Megatron-LM                                |
| Monitoring Tools     | DCGM, NVTOP, NVIDIA Nsight, MLPerf                                         |
| Networking Tools     | OFED (Mellanox), RDMA, RoCE, Infiniband Utilities                          |

---

## 2. 🧰 Key CLI Tools and Their Use

### 🔧 General System Diagnostics

```bash
lscpu              # CPU info
free -h            # Memory
vmstat 5           # Performance metrics
iostat -xz 1       # Disk I/O
systemctl status   # Service status
journalctl -xe     # System logs
```

### 🗃️ Lustre Storage

```bash
mount -t lustre
lfs df /mnt/lustre
lfs setstripe -c 4 /mnt/lustre/mydir
lctl get_param obdfilter.*.stats
```

### 🎮 NVIDIA GPU Management

```bash
nvidia-smi
nvidia-smi topo -m
dcgmi discovery -l
dcgmi stats -g 0
```

> **API**: `pynvml` (Python binding for NVML)

---

### 🌐 RoCE / RDMA Tools (Infiniband or Ethernet)

```bash
ibstat
ibv_devinfo
rdma link show
mlx5tool -d /dev/mst/mt4099_pci_cr0 qps show
ib_read_lat
```

---

### 🗂️ SLURM Cluster Scheduler

```bash
sbatch train.sh                   # Submit job
squeue -u $USER                   # Queue
scontrol show node                # Node info
sacct -j <jobid>                 # Accounting
sinfo                             # Partition info
```

---

### 📦 Container Tooling (GPU-Aware)

```bash
docker run --gpus all nvidia/cuda
podman run --hooks-dir=/usr/share/containers/oci/hooks.d ...
singularity exec --nv model.sif python train.py
nvidia-container-cli info
```

---

## 3. 🧠 LLM Training, GPU Virtualization & Benchmarking

| Tool / Framework   | CLI Example |
|--------------------|-------------|
| **DeepSpeed**      | `deepspeed train.py --deepspeed_config ds.json` |
| **Megatron-LM**    | `python pretrain_gpt.py` |
| **TensorFlow**     | `tf.train.Checkpoint()` (Python API) |
| **MLPerf**         | `make run_harness BENCHMARK=bert BACKEND=pytorch` |
| **Nsight**         | `nsys profile python train.py` |

---

## 4. 🗺️ Network Topology & Tool Placement

### 🛠 Management Plane (Out-of-band)
- **Hosts**: SLURM Controller, Fabric Manager, DCGM, Lustre MDS
- **Access**: Admin network via Leaf switches

### 🚀 Application Plane (In-band)
- **Hosts**: GPU compute nodes, NVLink, NVSwitch
- **Access**: RDMA/RoCE over Leaf-Spine topology
- **Storage**: Lustre clients

---

## 5. 🧪 Quick Tutorial Examples

### 🔍 Check GPU Health and Topology

```bash
nvidia-smi
nvidia-smi topo -m
dcgmi discovery -l
```

### 📁 Lustre Storage Commands

```bash
mount -t lustre
lfs df /mnt/lustre
lctl get_param obdfilter.*.stats
```

### 🚦 Run and Monitor Jobs (SLURM)

```bash
sbatch train_job.sh
squeue -u $USER
sacct -j 12345
```

### 📊 Benchmark LLM (MLPerf)

```bash
cd mlperf-inference
make run_harness BENCHMARK=bert BACKEND=pytorch
```

### 🐳 Run Training in Singularity

```bash
singularity exec --nv my_model.sif python train.py
```


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

# Simulating an HPC LLM Cluster on a Budget

* For the poor working peasant, bonded to a life of minimum wage, Building a physical HPC cluster with GPUs, InfiniBand, and Lustre is costly. However, don't despair! You can simulate or emulate much of the same architecture using public cloud services, desktop virtualization, or commodity hardware. Yes, you may have to sell your children into bondage (for the third time!) but hey, with the bump in salary you're likely to get you could one day buy them back (hopefully in better condition than you sold them!.

---

## 1. 🟢 Cloud-Based Simulation (Closest to Real Hardware)

### ✅ Cloud Providers
- **AWS**: `p4d`, `g5`, `inf2` (GPU), `c5n`, `hpc6id` (RDMA)
- **Azure**: `NDv4`, `HBv3`, `NCasT4_v3`

### 🔧 Tools to Install
- SLURM, Docker/Singularity, NVIDIA Drivers, Lustre FSx client
- DeepSpeed, Megatron-LM, MLPerf, DCGM

### 💡 Cost-Saving Tips
- Use spot instances
- FSx for Lustre (temporary performance Lustre)
- Stop VMs when idle

---

## 2. 🟡 Local Virtualized Lab (Desktop or Laptop)

### Tools:
- **VirtualBox**, **libvirt** + Vagrant
- Use `Mininet` to emulate a leaf-spine network
- Simulate storage with NFS instead of Lustre

### VM Roles:
- **mgmt-node**: SLURM controller, monitoring
- **compute-node-[1-2]**: Docker, CPU-only ML training
- **storage-node**: NFS as fake Lustre

---

## 3. 🔵 Commodity On-Prem Lab (~$500–$1000)

### Components:
- Refurbished Xeon/Threadripper nodes
- Consumer GPUs (RTX 3060/3080)
- Connect with 10GbE or fast Ethernet

### Capabilities:
- Real GPU training
- SLURM with GPU scheduling
- Containerized workloads

---

## 🧰 Bonus Tools

| Tool                | Purpose                                     |
|---------------------|---------------------------------------------|
| **MiniHPC**         | Small Ansible-based HPC cluster emulator    |
| **HPCBox**          | Cloud-based simulated HPC lab environment   |
| **Google Colab Pro+** | Free GPUs for small LLMs                  |
| **OpenHPC (CentOS)**| Deploy real SLURM/Lustre stacks via scripts|

---

## 🧵 Sample Stack for a Free VM Lab

```plaintext
- Control Node: Ubuntu VM
    - SLURM controller
    - Lustre client
    - MLPerf tooling
- Compute Nodes (2 VMs):
    - Docker + PyTorch (CPU-only)
    - CUDA toolkit (optional)
- Network:
    - Mininet or VLAN simulation
```

---

## ✅ Comparison Summary

| Method                | Pros                                 | Cons                                 | Estimated Cost |
|-----------------------|--------------------------------------|--------------------------------------|----------------|
| Public Cloud          | Real GPUs + RDMA + Lustre (FSx)      | Costly long-term                     | ~$1/hr (on demand) |
| Local VMs (VirtualBox)| Free, lightweight                    | No GPU, slow                         | $0             |
| Cheap On-Prem         | Real CUDA + SLURM                    | Setup effort, no NVLink              | $500–$1000     |
| Hybrid (Cloud + VM)   | GPU in cloud, control in VM          | Complexity in setup                  | Pay-as-you-go  |



# 🗺️ Lab Topology Diagrams

---

## 🟢 1. Cloud-Based Lab (AWS / Azure)

```plaintext
+----------------------+              +----------------------+
|   mgmt-node          |              |   gpu-node-1         |
| (SLURM Controller)   |<===========> | (Docker, CUDA, LLM)  |
| - slurmctld          |     EFA      | - nvidia-docker      |
| - lustre client      |              | - DeepSpeed, etc.    |
+----------------------+              +----------------------+
       |                                        |
       | FSx Lustre                             | GPU RDMA
       v                                        v
+----------------------+              +----------------------+
|     FSx Lustre       |              |   gpu-node-2 (opt)   |
|   (Elastic Storage)  |              |   same stack as node1|
+----------------------+              +----------------------+

Network: VPC with HPC subnet, optionally using EFA (RDMA over ENA)
```

---

## 🟡 2. Local VirtualBox/KVM Simulated Cluster

```plaintext
+------------------------+     +------------------------+
|    mgmt-vm             |     |   compute-vm-1         |
| - SLURM controller     |<--->| - Docker + PyTorch     |
| - NFS client           |     | - CPU only             |
+------------------------+     +------------------------+
           |                         |
           v                         v
    +-------------------------+     +------------------------+
    |   NFS storage-vm        |     |   compute-vm-2 (opt)   |
    | - fake Lustre/NFS       |     | - Docker + ML stack    |
    +-------------------------+     +------------------------+

Network: Host-only or bridged (e.g. 192.168.56.x)
```

---

## 🔵 3. Commodity On-Prem Hardware Cluster

```plaintext
+------------------------+       +--------------------------+
|   mgmt-node (Refurb PC)|<=====>| compute-node-1 (GPU PC)  |
| - SLURM + Docker       |  LAN  | - NVIDIA GPU + Docker    |
| - Munge + NFS client   |       | - DeepSpeed, etc.        |
+------------------------+       +--------------------------+
                                         |
                                         v
                               +--------------------------+
                               | compute-node-2 (GPU PC)  |
                               | - Same stack as node-1   |
                               +--------------------------+

Network: Local Ethernet or 10GbE switch
```


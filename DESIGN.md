# Modern HPC Compute infrastructure Design Process Walkthrough

* This guide can be used as a rough consulting template for designing an HPC cluster based on customer requirements.
* The upper bound on all our technical assumptions is cost: Assume the customer can afford the solution as described.

## Identifying the Central Use Case

* Key starting question: What is the customer’s workload? Characterise the customers Use Case and workload in as much detail as possible. 

1. Training vs. inference? Vision? LLMs? Scientific computing?
2. Batch size, memory needs, scaling profile?
3. Timeline (burst vs. persistent workloads)?

* What options do we have in terms of Deployment model?

1. Cloud?
2. On-prem?
3. Hypbrid?

* Budget or sustainability constraints?

1. Energy consumption over time and energy consumption targets?
2. OPEX vs. CAPEX arrangements? (Utility Computing or Capitsal Outlay?)

### EXAMPLE SCENARIO:

**"A customer is training large language models (13B–30B parameters), with requirements for 10 TFLOPs per node sustained throughput, low latency interconnects, and plans to scale to 256 GPUs."**

* Load type: Training Load, with inference expected as the next use case for evaluating the model.
* Throughput per node (sustained): 10 TFLOPS
* Latency sensitivity: Implicit that in training and inference low latency is required (interconnects must be "fast")
* Scalability: Mentioned in terms of GPUs, and at this point we are told that 256 GPUs is the "next scaling horizon"

### Defining the Architecture Tiers

* We know the architecture will be composed of a standard set of tiers. Our task then is to define those tiers.
* Break the architecture down into a) Architecture Layer b) Design Component c) Commercially available Technologies for implementation

1. Compute Layer: GPU servers / AI accelerators, NVIDIA H100 (SXMs preferred), AMD Instinct MI300x
2. Network Layer:	High-speed interconnect for GPU-GPU comms, NVIDIA InfiniBand HDR/NDR, ConnectX-7
3. Control/Management Layer: Host CPUs, orchestrators, storage front ends, x86 (AMD EPYC), Arm (with BlueField DPU), Kubernetes
4. Storage Layer: Fast scratch + model checkpoint	NVMe SSDs, Lustre or BeeGFS
5. Cooling Layer:	Immersion-ready design	Single-phase immersion, Smart enclosure layout
6. Security Layer: Segmented data planes & telemetry (Remote Server Management Protocols e.g iDrac, LOM/ILOM) NVIDIA BlueField DPU (isolate ML pipeline control plane)
7. Middleware Layer: Parallel Job Schedulers, HPC Operating System, Frameworks for distributed training: PyTorch (torch.distributed), ensorFlow (via Horovod or XLA), MXNet, JAX, and more

### Produce a "Skeleton Design" of the Cluster Architecture

* Having defined the high level tiers of the system we can now drill down into each tier to produce the actual cluster design. This is also high level but it begins to illustrate the relationships between the tiers and what those tiers are composed of.

**High Level Model:**

* The architecture primarily consists of two major components:

- 400Gbps network fabric for GPU data communication, including routed communications over a high capacity network core router (L3 switch / "Spine") and L2 ToR switches 
- GPU Compute nodes which bundle GPU, Control-Compute, Volatile Scratch memory and Local Storage in each node rack. Each rack should come with advanced cooling (ideally liquid immersion cooling)

**Rack Design:**

- 8 GPU nodes per rack (each node: 8x H100 SXM, 2x AMD EPYC, 4TB DDR5)
- 1 Top-of-Rack InfiniBand switch (NDR 400Gbps)
- Redundant ToRs connected via spine switches (leaf-spine)
- ConnectX-7 NICs (per node) with RoCEv2 enabled
- BlueField-3 DPU per node for storage + network offload

**Network Design:**

- Leaf and Spine network and components in detail ...?

**Storage Design:**

- Storage is provisioned and accessed how ... ?
- What is the use of Node-local NVMe for temporary data (checkpointing, "scratch space")
- Parallel FS for model checkpoints (what PFS do we use)
- Optionally, integrate object storage for artifact retention

**Security Design**

* Data segregation
* Communication segregation
* Data protection at rest and in flight
* Management/Control Plane sgregation from Data Plane
* Defining Dev/Prod/UAT in an HPC environment?
* Access control, Secrets Management
* Standards Compliance ?

**Efficiency, Cooling & Sustainability Design**

As carbon efficiency is becoming more and more desired and energy conservation is becoming a practical need, you’ll want to:

1. Explore immersion-ready chassis for compute node rack (e.g., Asperitas or Submer)
2. Reduce cooling overheads (PUE → < 1.05) ... Define PUE, what does "< 1.05" mean?
3. Include DPU telemetry (BlueField SmartNIC to monitor + enforce QoS) ... How does this relate to Sustainability?

*Relevant Metrics:*

* Energy per training run metric
* Firmware and BIOS tuning for thermal optimization
* Sustainable Metal Cloud integration (if hybrid or cloud-deployed)

*Explore further:*

- Energy per training run metric
- Firmware and BIOS tuning for thermal optimization
- Sustainable Metal Cloud integration (if hybrid or cloud-deployed)

**"Frontend Network" (Application Network)**

- How do the user applications access the results of the HPC cluster (assuming the result is a properly trained LLM model)
- Applications, and ML pipelines access the compute results ... ?

### Quantify: Put some numbers to the "Skeleton Design"

* Once we have a skeleton design of the cluster (see previous section) we can try quantify the details based on our earliest assumptions about the scale of the solution.
* Question: For ML Training of a model in the range 13 - 30 Billion Parameters, how many GPUs do we need to finish training in a "reasonable amount of time" (define this)?
* Once the GPU count (total, then broken down per rach) is estimated we can determine the likely aggregate bandwidth over the network spine, power consumption total and therefore the immersion cooling requirements

1. Total GPU count
2. Aggregate network bandwidth
3. Power per rack
4. Immersion cooling requirements (density, fluid type)

### Justify Technology Choices in Detail

* At this point we need to drill into the details of the low level technology choices for each design component to understand their role and justification in the overall design. For our specific HPC design, start with the following activities:

1. Explain why you choose SXM vs PCIe GPUs
2. Show awareness of NUMA boundaries, memory locality
3. Talk through DPU offload use cases (storage, networking, telemetry)
4. Why NCCL?
5. Why RDMA and RoCE?
6. What is NVLink and why do we need it?
7. What's NVMe?

### Workload Mapping for Scaling Assessment

* We need to map the intended workload to the Compute, Network and Storage components of our architecture in order to determine the scaling/scalability of the system to the overall use-case.

1. Assess the performance expectations of the architecture: Use benchmark expectations: e.g., 1 node = 2.5 TFLOPs sustained; 32 nodes = 80 TFLOPs
2. For a Model of X-billion parameters how many TFLOPS will be required to complete training in Y-timespan?
3. Evaluate and Explain the scalability of the architecture in terms DDP (Distributed Data Parallel) or ZeRO scaling
4. Assess the scalability of the job schedulers (Slurm, Kubernetes) on the system
5. Discuss storage IOPS needs for checkpointing large LLMs on local compute nodes (assuming local storage is being used)

## Benchmarking our Solution

* Having completed the design and assessed the high level performance capabilities and parameters, benchmark your design
* Overall Hardware Performance for standardised loads (??? what hardware benchmarking tools to use?) 
* O.S and Middleware performance benchmarks (MLperf for machine learning workload performance benchmarking)
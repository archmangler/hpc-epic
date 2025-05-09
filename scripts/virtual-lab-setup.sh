#!/bin/bash

# engeneon_virtual_lab_setup.sh
# Simulated local HPC cluster using VirtualBox VMs

echo "[INFO] Creating virtual network (host-only)..."
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1

# Create base VM
VM_BASE_NAME="hpc-base"
VM_OS_ISO="/path/to/ubuntu.iso"

echo "[INFO] Creating base VM: $VM_BASE_NAME"
VBoxManage createvm --name "$VM_BASE_NAME" --register
VBoxManage modifyvm "$VM_BASE_NAME" --memory 2048 --cpus 2 --nic1 hostonly --hostonlyadapter1 vboxnet0
VBoxManage createhd --filename "$VM_BASE_NAME.vdi" --size 20000
VBoxManage storagectl "$VM_BASE_NAME" --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach "$VM_BASE_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_BASE_NAME.vdi"
VBoxManage storageattach "$VM_BASE_NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$VM_OS_ISO"
VBoxManage modifyvm "$VM_BASE_NAME" --boot1 dvd --boot2 disk

echo "[INFO] Start the VM and install Ubuntu manually. Then clone it into compute/mgmt nodes."
echo "[NOTE] After installation, install: SLURM, Docker, OpenSSH server, and any required ML tooling."


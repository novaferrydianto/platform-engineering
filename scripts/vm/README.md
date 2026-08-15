# Dev VM provisioning

Two ways to get a ready-to-use Ubuntu 24.04 guest for this repo in VMware
Workstation Pro. Both install the same toolchain `scripts/bootstrap.sh`
checks for, with **Podman** (not Docker) as the container engine — the
`podman-docker` package makes `docker build`/`docker run` resolve to Podman
transparently.

| | Vagrant (`Vagrantfile`) | Cloud-init (`cloud-init/`) |
|---|---|---|
| Cost | Requires the **paid** `vagrant-vmware-desktop` plugin for VMware | Free — no plugin |
| Setup effort | Low (`vagrant up`) | Higher (manual VM + seed ISO) |
| Repo access in guest | Auto-synced folder | Manual `git clone` |
| Also works with | VirtualBox (free, for testing the Vagrantfile itself) | — |

If you don't already have the VMware Vagrant plugin and don't want to buy
it, use the cloud-init path.

## Option A — Vagrant

```bash
vagrant plugin install vagrant-vmware-desktop   # paid plugin; skip if using VirtualBox instead
cd scripts/vm
vagrant up --provider=vmware_desktop            # or --provider=virtualbox
vagrant ssh
cd platform-engineering && scripts/bootstrap.sh
```

The repo root is synced to `/home/vagrant/platform-engineering` inside the
guest. Ports `3000` (portal frontend) and `7007` (portal backend) are
forwarded to the host, so `http://localhost:3000` works from Windows once
`yarn dev` is running in the guest.

## Option B — cloud-init (no Vagrant, no paid plugin)

1. **Put your SSH public key in `cloud-init/user-data`** — replace the
   placeholder under `ssh_authorized_keys`. Password login is disabled, so
   this is the only way to reach the VM.

2. **Download the Ubuntu 24.04 cloud image** and convert it to VMware's disk
   format:

   ```bash
   curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
   qemu-img convert -f qcow2 -O vmdk noble-server-cloudimg-amd64.img platform-engineering.vmdk
   ```

3. **Build the seed ISO** from `user-data` + `meta-data` (needs
   `genisoimage`/`mkisofs`/`cloud-localds` — available in WSL, or via
   `oscdimg` from the Windows ADK on native Windows):

   ```bash
   # Linux / WSL:
   genisoimage -output seed.iso -volid cidata -joliet -rock scripts/vm/cloud-init/user-data scripts/vm/cloud-init/meta-data

   # Windows (Windows ADK's oscdimg), from a PowerShell prompt in scripts/vm/cloud-init:
   oscdimg -n -m -lcidata seed_files_dir seed.iso   # copy user-data/meta-data into seed_files_dir first
   ```

4. **Create the VM in VMware Workstation Pro**: New VM → "I will install the
   operating system later" → attach `platform-engineering.vmdk` as the
   primary disk → attach `seed.iso` as a CD-ROM → 4 vCPU / 8GB RAM
   recommended → Network Adapter set to **NAT** (with port forwarding for
   3000/7007) or **Bridged** if you want the VM reachable directly on your
   LAN.

5. **Boot the VM.** cloud-init runs `cloud-init/user-data` on first boot,
   installing the same toolchain as `provision.sh`. Watch progress with
   `sudo cloud-init status --wait` inside the guest, or check
   `/var/log/cloud-init-output.log`.

6. **Clone the repo manually** — this path has no host↔guest shared folder:

   ```bash
   ssh dev@<vm-ip>
   git clone <your-fork-url> platform-engineering
   cd platform-engineering && scripts/bootstrap.sh
   ```

## Testing NetworkPolicy locally (Cilium)

kind's default CNI (kindnet) doesn't enforce `NetworkPolicy` — the golden
path charts and `infrastructure-modules/kubernetes/namespace`'s default-deny
would apply successfully but do nothing, silently. Once `provision.sh` has
run (installs `kind` + the `cilium` CLI), bring up a cluster with Cilium
actually enforcing policy:

```bash
scripts/vm/setup-kind-cilium.sh
```

This mirrors what each cloud module does in production — EKS's native VPC
CNI policy agent, GKE's Calico, AKS's Cilium — so `helm install` against this
local cluster tells you whether a NetworkPolicy actually works, not just
whether it's syntactically valid.

## VMware Workstation Pro settings that matter

- **Nested virtualization** (VM Settings → Processors → "Virtualize
  Intel VT-x/EPT") is **not needed** for anything in this repo. `kind`'s
  "nodes" are containers, not VMs, so `scripts/vm/setup-kind-cilium.sh`
  never touches a hypervisor inside the guest. Podman itself doesn't need it
  either — the guest OS is already Linux, so containers run natively, unlike
  on a Windows/macOS host where Podman has to boot a Linux VM
  (`podman machine`) just to get a kernel.
- **Networking**: NAT + forwarded ports is simplest for reaching the portal
  from the Windows host; Bridged is better if other machines on your network
  need to reach it too.
- **Disk size**: the Ubuntu cloud image ships with a small virtual disk.
  Resize with `vmware-vdiskmanager -x 60GB platform-engineering.vmdk` before
  first boot if you need more room (`node_modules` in `idp-portal/` alone
  can exceed 1GB).

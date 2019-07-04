# Ubuntu-18.04 Install

## Procedure

This document outlines the setup procedure for Ubuntu-18.04. If you intend to setup docker with user-namespace remapping, please ensure that you create an `administrator` user first while installing the OS and manually create additional users from the command line with a uid of 1026 and higher.

### Step 01.00 Setup

#### Step 01.01: Install operating system.

Download the iso and verify the checksum
```bash
# ubuntu
sha256sum ubuntu-18.04.2-desktop-amd64.iso

# macosx
shasum -a 256 ubuntu-18.04.2-desktop-amd64.iso
```

Software Packages: `Normal installation`.

When ask to select partition, choose option to
Erase entire disk and install Ubuntu.

Select custom hard disk partition:
```
512MB    fat32   /boot/efi     boot,esp (EFI System Partition)
460000MB ext4    /             (root)
```

Setup initial user:
```bash
Real Name: Administrator
Username : administrator
```

#### Step 01.02: Install additional packages.

```bash
sudo apt-get install localepurge
sudo apt-get install build-essential
```

Add 32-bit compatibility libraries.
```bash
sudo dpkg --add-architecture i386
$ sudo apt update
$ sudo apt install libc6:i386
```

#### Step 01.03: Install graphics drivers from PPA repositories.

```bash
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update

# check recommended drivers
ubuntu-drivers devices

== /sys/devices/pci0000:00/0000:00:01.1/0000:02:00.0 ==
modalias : pci:v000010DEd00001D81sv000010DEsd00001218bc03sc00i00
vendor   : NVIDIA Corporation
model    : GV100 [TITAN V]
driver   : nvidia-driver-415 - third-party free
driver   : nvidia-driver-410 - third-party free
driver   : nvidia-driver-396 - third-party free
driver   : nvidia-driver-418 - third-party free recommended
driver   : nvidia-driver-390 - distro non-free
driver   : xserver-xorg-video-nouveau - distro free builtin


# install driver automatically
sudo ubuntu-drivers autoinstall

# or selectively
sudo apt install nvidia-418
```

Ensure you are using only Nvidia proprietary drivers by blacklisting `Nouveau`, Ubuntu's built-in Open Source driver.

Create blacklist-nouveau.conf
```bash
sudo nano /etc/modprobe.d/blacklist-nouveau.conf
```

Include the following:
```
blacklist nouveau
options nouveau modeset=0
```

Run the following to apply the changes:
```bash
sudo update-initramfs -u
```

Edit GRUB entries:
- Enable IOMMU
- Disable CPU Spectre/Meltdown workaround
```
sudo nano /etc/default/grub

GRUB_CMDLINE_LINUX_DEFAULT="quiet nouveau.modeset=0 splash intel_iommu=on pti=off spectre_v2=off l1tf=off nospec_store_bypass_disable no_stf_barrier"
```

The paramter nouveau.modeset=0 prevents the loading of all radeon drivers
until the X-Server is started(Namely your Desktop comes up). Therefore the boot up time
can be used by the vfio-pci driver to grab the GPU we want to use in the KVM.

Update GRUB config:
```bash
sudo update-grub
sudo update-grub2
```

Ensure that the nvidia driver is enabled by default:
```bash
sudo prime-select nvidia
```

```bash
# reboot
sudo reboot -i NOW
```

#### Step 01.04: Create groups and users.

```bash
sudo addgroup --gid 65536 developers
```

#### Step 01.05: Create users.

```bash
# create user myusername
sudo adduser --home /home/myusername --uid 1028 myusername

# add the user myusername to different groups
sudo adduser myusername developers
sudo adduser myusername users
sudo adduser myusername dialout
sudo adduser myusername audio
sudo adduser myusername video

# grant the user sudo privileges
sudo visudo

myusername  ALL=(ALL:ALL) ALL
```

#### Step 01.06: Create folders.

```bash
# create folders and change ownership
sudo mkdir /backup /data /project /tool
sudo chgrp -R developers /backup /data /project /tool
sudo chown -R myusername /backup /data /project /tool
```

#### Step 01.07: Edit fstab to automount a secondary hard drive.

You can launch the `disks` application to format the secondary drive using `ext4` partition.

Determine drive information:
```bash
lsblk

sda           8:0    0   5.5T  0 disk /media/myusername/storage
sdb           8:16   1 114.6G  0 disk
└─sdb1        8:17   1 114.6G  0 part /media/myusername/128GB001
nvme0n1     259:0    0 465.8G  0 disk
├─nvme0n1p1 259:1    0   512M  0 part /boot/efi
└─nvme0n1p2 259:2    0 465.3G  0 part /
```

Check partition information.
Parted will tell you your drive’s file system. Look for whatever `File system` is printed in the terminal.
```bash
sudo parted /dev/sda -l

Model: ATA WDC WD60EFRX-68L (scsi)
Disk /dev/sda: 6001GB
Sector size (logical/physical): 512B/4096B
Partition Table: loop
Disk Flags:

Number  Start  End     Size    File system  Flags
 1      0.00B  6001GB  6001GB  ext4


Model: SanDisk Ultra Fit (scsi)
Disk /dev/sdb: 123GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start   End    Size   Type     File system  Flags
 1      16.4kB  123GB  123GB  primary  ext4


Model: Samsung SSD 970 EVO 500GB (nvme)
Disk /dev/nvme0n1: 500GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End    Size   File system  Name                  Flags
 1      1049kB  538MB  537MB  fat32        EFI System Partition  boot, esp
 2      538MB   500GB  500GB  ext4
```

Format the drive from the command line:
```bash
sudo fdisk /dev/sda

# Choose “n” to create a new partition, then “p” then “1” to create a new primary partition. Just use defaults for the sector numbers. Then “w” to write the data to the disk.

sudo mkfs -t ext4 /dev/sda
```


Create a mount folder:
```bash
sudo mkdir -p /mnt/storage
#sudo chown -R myusername:developers /mnt/storage
```

Backup fstab:
```bash
mkdir -p /backup/config/etc
sudo cp /etc/fstab /backup/config/etc
```

Find the UUID for your internal drive:
```bash
sudo blkid
/dev/nvme0n1: PTUUID=" " PTTYPE="gpt"
/dev/nvme0n1p1: UUID=" " TYPE="vfat" PARTLABEL="EFI System Partition" PARTUUID=" "
/dev/nvme0n1p2: UUID=" " TYPE="ext4" PARTUUID=" "
/dev/sda: LABEL="storage" UUID="abcdef-abcd" TYPE="ext4"
/dev/sdb1: LABEL="128GB001" UUID=" " TYPE="ext4"
```

Edit fstab:
```bash
sudo nano /etc/fstab
```

Going off the information that the lsblk command told us, we know the file system we need is /dev/sda1. Create the following entry in the `/etc/fstab` file:

```bash
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# internal hard disks
UUID=abcdef-abcd  /mnt/storage ext4 defaults,noatime,nofail 0 2
```

After that press “Ctrl + O” to save the newly edited file to your system. When you reboot, you’ll be able to access your new hard drive inside the Storage folder located in your home directory.

Reboot the system. The internal hard disk will now be available on `/mnt/storage`

Recursively change permissions:
```bash
sudo chown -R myusername:developers /mnt/storage
```

Create a symbolic link to folders within the internal storage drive to your home folder:
```bash
mkdir -p /mnt/storage/mount
ln -s /mnt/storage/mount ~/mount
```

Create additional symbolic links for `~/Documents` and `~/Downloads` folders
so that they point to the internet storage drive:

```bash
# remove existing folders
rm -Rf ~/Documents ~/Downloads

# create folders on the internal storage drive
mkdir -p /mnt/storage/download
mkdir -p /mnt/storage/document

# create symbolic links
ln -s '/mnt/storage/document' /home/myusername/Documents
ln -s '/mnt/storage/download' /home/myusername/Downloads
```


#### Step 01.08: Recursively change permissions on an external USB drive.

Recursively change group permissions to `developers`:
```bash
sudo chgrp -R developers '/media/myusername/128gb-usb'
sudo chmod -R g+rwX '/media/myusername/128gb-usb'
```

### Step 02.00: Install applications

#### Step 02.01: Install google chrome.

```bash
# update sources.list
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'

# add signing key
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# verify
apt-key list

pub   dsa1024 2007-03-08 [SC]
      4CCA 1EAF 950C EE4A B839  76DC A040 830F 7FAC 5991
uid           [ unknown] Google, Inc. Linux Package Signing Key <linux-packages-keymaster@google.com>
sub   elg2048 2007-03-08 [E]

# install
sudo apt update
sudo apt install google-chrome-stable
```

#### Step 02.02: Install atom editor.

```bash
# install
sudo add-apt-repository ppa:webupd8team/atom
sudo apt update; sudo apt install atom

# remove
sudo apt remove --purge atom
```


### Step 03.00: Setup and configure docker.

#### Step 03.01: Remove an existing docker installation.

**Important:** Skip this step if you're installing Ubuntu on your system
for the first time.

Stop the docker service:
```bash
sudo systemctl stop docker

sudo systemctl status docker
```

Remove docker:
```bash
sudo apt remove docker docker-ce docker-compose
```

Remove docker configuration files

If docker has been run once without user namespace remapping, `/var/lib/docker`
will contain configuration files, images and containers.

We should ideally delete these files and images, to save on space before
enabling user namespace remapping.

**Optional:** If you have previously installed Ubuntu on a `btrfs` filesystem
you will have to delete existing `btrfs` subvoluments. If not, you can skip this step.

Delete `btrfs` subvolumes if it exists.
```bash
sudo -s
cd /var/lib/docker
btrfs subvolume delete btrfs/subvolumes/*

# delete subvolumes for a specific user
cd /var/lib/docker/1028.999
btrfs subvolume delete btrfs/subvolumes/*
```

Remove existing docker configuration files:
```bash
sudo -s
rm -Rf /var/lib/docker
```

#### Step 03.02: Configure user-namespace remapping.

Before installing docker, we will add some configuration files to setup
usernamespace remapping.

Specify subuid and subgid.

Edit `/etc/subuid`
```bash
sudo nano /etc/subuid

myusername:1028:1
myusername:100000:65536
```

Get the docker group id:
```bash
getent group docker
docker:x:999:myusername
```

Use the obtained gid `999` to set the subgid, for specifying the docker group
for setting the user group, for user namespace remapping. This will allow files
created on the host to belong to $USER:docker.

Edit /etc/subgid
```bash
sudo nano /etc/subgid

myusername:999:1
myusername:100000:65536
```

Edit /etc/docker/daemon.json
```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

```json
{
    "dns": ["8.8.8.8", "8.8.4.4"],
    "userns-remap": "myusername",
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
```

**Note:** Ensure that you don't have extraneous commas in the daemon.json file.
It will cause errors and prevent the docker daemon from starting.


#### Step 03.03: Install Docker CE.

```bash
sudo apt-get update

# install required packages
sudo apt install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# add docker repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# update repositories
sudo apt update

# make sure you are about to install from the Docker repo instead of the default Ubuntu repo
apt-cache policy docker-ce

# install
sudo apt install docker-ce

# check status
sudo systemctl status docker

# add user to the docker group
sudo usermod -aG docker myusername
```

Configure Docker to start on boot:
```bash
sudo systemctl enable docker
```

Reboot the system. After the system comes up, check that the kernel options were properly assigned and that the docker service is running with user namespaces enabled.

This can be verified by looking at the contents of `/var/lib/docker` and verifying the existence of new user-specific folders:
```bash
sudo -s
cd /var/lib/docker
ls -la

total 12
drwx--x--x  3 root   root   4096 Dec 29 18:45 .
drwxr-xr-x 66 root   root   4096 Dec 29 18:45 ..
drwx------ 14 myusername docker 4096 Dec 29 18:45 1028.999
```

Here are the steps to change the location of the `/var/lib/docker` folder to an internal drive:
```bash
# move docker files
sudo -s
systemctl stop docker
mv /var/lib/docker/* /mnt/storage/docker/
ln -s /mnt/storage/docker /var/lib/docker
systemctl start docker
```

If you need to restart the docker daemon and docker service, enter the following command:

```bash
sudo systemctl daemon-reload; sudo systemctl restart docker;
```
or

```bash
sudo dockerd --userns-remap="myusername:myusername"
```
if you didn't make an entry in daemon.json

The Docker Engine applies the same user namespace remapping rules to all containers, regardless of who runs a container or who executes a command within a container.

#### Step 03.04: Install nvidia-docker2.

Configure repositories:
```
# add nvidia-docker repository
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
```

Install the `nvidia-docker2` package and reload the docker daemon configuration:
```
sudo apt-get install nvidia-docker2
sudo pkill -SIGHUP dockerd
```

#### Step 03.05: Install docker-compose.

Run this command to download the latest version of Docker Compose:
```
# download
sudo curl -L https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

# apply executable persmissions
sudo chmod +x /usr/local/bin/docker-compose

# test the installation
docker-compose --version
docker-compose version 1.24.0, build 0aa59064
```

#### Step 03:06: Test running a docker image

Test the docker installation:
```bash
docker run --rm hello-world
docker run --rm -it ubuntu:xenial cat /etc/issue
Ubuntu 16.04.5 LTS \n \l
```

#### Step 03.07: Test NVIDIA Docker2 Image

Test NVIDIA OpenGL by running the glxgears example:
```
git clone https://gitlab.com/nvidia/samples.git /project/software/infrastructure/docker/nvidia/samples
cd /project/software/infrastructure/docker/nvidia/samples/opengl/ubuntu16.04/glxgears

# build the docker image
docker build \
  --file Dockerfile \
  -t nvidia/opengl:glxgears-ubuntu16.04 .

# run the docker image
xhost +local:root
docker run -it \
  --runtime=nvidia \
  -e DISPLAY \
  -e QT_GRAPHICSSYSTEM=native \
  -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  nvidia/opengl:glxgears-ubuntu16.04
xhost -local:root
```

Test NVIDIA CUDA image and check if GPUs are reported correctly by nvidia-smi:

```
docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi
```

#### Step 03:08: Calculating the UID remapping in docker containers

##### root user in a docker container

A `root` user will have `UID=0` inside a container.

The root user will get remapped to `myusername:1028` for the following `UID` mapping values in `/etc/subuid`:

```bash
myusername:1028:1
myusername:100000:65536
```

##### non-root user in a docker container

If you have a user `developer` with `UID=1000` in a container.

The second non-root user in a container, e.g. `developer:1000` will get remapped to `100000 + (1000-1)= 100999` on the host, for the following `UID` mapping values in `/etc/subuid`:

```bash
myusername:1028:1
myusername:100000:65536
```

#### Step 03:09:Enable volume sharing

Create a set of common folders that will act as volume mount points for a docker container.

If you plan on using an external volume mount or a separate nvme drive dedicated for storing
docker images, create a symbolic link to the volume mount point or nvme drive instead.

Find disk usage:
```bash
df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        28G  9.3G   17G  36% /

df -h /media/myusername/nvme
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p1  469G   18G  428G   4% /media/myusername/nvme
```

```bash
mkdir -p ~/mount/backup ~/mount/data ~/mount/project ~/mount/tool
```

Alternatively, you can create a symbolic link to folders within the internal storage drive to your home folder:
```bash
mkdir -p /mnt/storage/mount
ln -s /mnt/storage/mount ~/mount
```

```bash
mkdir -p /mnt/storage/mount/backup /mnt/storage/mount/data /mnt/storage/mount/project /mnt/storage/mount/tool
```

If the docker user `developer` has `uid=1000` and `gid=1000`,
it will be user_namespace remapped to `uid=100999` and `gid=100999`.

When you launch a docker image and mount a volume, the volume mounts will initially
be owned by root within the container because of user namespace remapping. Change
the permission of one of the volume mounts from within the container, to double check
the resulting uid:gid on the host and then chown all the volume mount points from
the host.

```bash
# run this command from within the container
sudo chown 1000:1000 /project

# run this command from the host
cd ~/mount
ls -la
drwxrwxr-x. 1 100999 100999 464 Oct 29 19:46 project
```

Define an additional group on the host and add the current user to the group
to be able to share data generated by a non-root user within the docker container.

```bash
sudo addgroup --gid 100999 docker-developer
sudo usermod -aG docker-developer myusername
```

Change permissions recursively for the mount points so that they are accessible
to a non-root user from within the container:
```bash
# use this command for normal ~/mount folder
sudo chmod -R ug+rw ~/mount; sudo chown -R 100999:docker-developer ~/mount;

If your `~/mount` folder is symbolically linked to `/mnt/storage/mount`, type the following commands to enable access from the docker container:
```bash
sudo chmod -R ug+rw /mnt/storage/mount; sudo chown -R 100999:docker-developer /mnt/storage/mount;
```

Log-off and log back in for the folder permissions to take effect.

### Step 04.00: Setup SSH for remote access

#### Step 04.01: Install OpenSSH

Type the following commands to install OpenSSH.

```bash
sudo apt-get install openssh-client openssh-server
```

#### Step 04.02: Generate RSA Keys for SSH users

Generate RSA keys for myusername:

```bash
su myusername
cd ~/
ssh-keygen -t rsa -b 8192
```

Explicity set permissions for .ssh files
```bash
cd .ssh
chmod go-r id_rsa
```

Run ssh-agent
```bash
eval $(ssh-agent)
ssh-add
ssh-add -l
```

Restart ssh:

```bash
sudo service ssh restart
```

Login using ssh in debug mode:

```bash
ssh -vv myusername@ml-platform
```

Check the ssh logs for info on failed login attempts:

```bash
cat /var/log/auth.log
```

#### Step 04.03: Configure SSH

Create a list of authorized users:

```bash
cd ~/.ssh
touch authorized_keys
cat id_rsa.pub >> authorized_keys
chmod 600 authorized_keys
```

Ensure that id_rsa is only accessible by the current user:
```bash
cd ~/.ssh
chmod go-r id_rsa
```

Append additional users to the list of authorized users on host domain:

```bash
cd ~/.ssh
cat myusername@ml-platform.pub >> authorized_keys
chmod 600 authorized_keys
```

Make a backup of your sshd_config file by copying it to your home directory, or by making a read-only copy in /etc/ssh by doing:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.factory-defaults
sudo chmod a-w /etc/ssh/sshd_config.factory-defaults
```

Modify the sshd_config file

```bash
sudo gedit /etc/ssh/sshd_config
```

Disable root login and change the SSH port to something different than the standard port 22.

```
Port 22
Protocol 2
PermitRootLogin no
```

Disable tunneled clear text password authentication. See SSH/OpenSSH/Configuring - Community Ubuntu Documentation for more details.

To disable password authentication, look for the following line in your sshd_config file:

```
#PasswordAuthentication yes
```

replace it with a line that looks like this:

```
PasswordAuthentication no
```

Restart the ssh server:

```bash
sudo service ssh restart
```

Once you have saved the file and restarted your SSH server, you shouldn't even be asked for a password when you log in.

Add the list of servers to your /etc/hosts file

```bash
$ sudo gedit /etc/hosts

##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost

# This server's hostname and FDQN.
192.168.252.92  ml-platform   # Ubuntu-18.04 64-bit physical machine.
```

#### Step 04.04: SSH Hardening

Harden the server using the instructions outlined in How to secure an Ubuntu 12.04 LTS server - Part 1 The Basics | The Fan Club.

SSH Hardening - disable root login and change port.

The easiest way to secure SSH is to disable root login and change the SSH port to something different than the standard port 22. Before disabling the root login create a new SSH user and make sure the user belongs to the admin group (see step 4. below regarding the admin group).

Protect su by limiting access only to admin group.

```bash
sudo groupadd admin
sudo usermod -aG admin myusername
sudo dpkg-statoverride --update --add root admin 4750 /bin/su
```

Restart the ssh server:

```bash
sudo service ssh restart
```

If you change the SSH port also open the new port you have chosen on the firewall and close port 22.

```bash
sudo ufw enable
sudo ufw status
sudo ufw default deny
sudo ufw allow 22/tcp
```

See UFW - Community Ubuntu Documentation, for more details.

To test if everything is working correctly, try to login using the new ssh port

```bash
ssh -p 22 myusername@ml-platform
```

To clone a repo, using the following command syntax

```bash
git clone ssh://git@titan:[port]/[path-to-git-repository]
```

To test the ssh connection, use the ssh command with the verbose option:

```bash
ssh -p 22 -vv myusername@ml-platform
```

To transfer files using scp between two computers, type the following command:

```bash
# copy a single file
scp -P 22 <filename> myusername@ml-platform:/home/myusername/Downloads

# recursively copy the contents of an entire folder
scp -r -P 22 <folder> myusername@ml-platform:/home/myusername/Downloads
```

### Step 05.00: Configure NFS support.

#### Step 05.01: Install required packages for Ubuntu 18.04.

NFS support files common to client and server are available in the nfs-common package.
```bash
sudo apt-get install nfs-common
```

#### Step 05.02: Mount an NFS filesystem in read/write mode from Ubuntu 18.04.

Create nfs mount points:
```bash
mkdir ~/Repository
sudo mkdir -p            /backup /data /project /tool /media/myusername/diskstation/backup /media/myusername/diskstation/download
sudo chown -R myusername /backup /data /project /tool /media/myusername/diskstation/backup /media/myusername/diskstation/download
sudo chgrp -R developers /backup /data /project /tool /media/myusername/diskstation/backup /media/myusername/diskstation/download
```

To manually mount the nfs share:
```bash
sudo mount -t nfs -o proto=tcp,port=2049 191.168.252.3:/volume1/project /project
```

To automatically mount the NFS share, edit the /etc/fstab file as follows:

```bash
su
gedit /etc/fstab

# automount synology shared folders
192.168.252.27:/volume1/backup       /media/myusername/diskstation/backup   nfs auto 0 0
192.168.252.27:/volume1/download     /media/myusername/diskstation/download nfs auto 0 0
192.168.252.27:/volume1/data         /data        nfs auto 0 0
192.168.252.27:/volume1/project      /project     nfs auto 0 0
192.168.252.27:/volume1/tool/ubuntu  /tool        nfs auto 0 0
```

Type the following command into a terminal to mount the shared folder
```bash
sudo mount -a
```

#### Step 05.03: Create an .aliases.sh file to make it easier to mount the nfs shares.

```bash
gedit ~/.aliases.sh
```

```bash
#!/bin/bash

# Filename    : ~/.aliases.sh
# Description : Script to setup aliases for the current user.

# Function to mount diskstataion volumes.
function mount_diskstation {
  sudo mount -t nfs -o proto=tcp,port=2049 192.168.252.27:/volume1/repository  /home/myusername/Repository;
  sudo mount -t nfs -o proto=tcp,port=2049 192.168.252.27:/volume1/backup      /media/myusername/diskstation/backup;
  sudo mount -t nfs -o proto=tcp,port=2049 192.168.252.27:/volume1/download    /media/myusername/diskstation/download;
  sudo mount -t nfs -o proto=tcp,port=2049 192.168.252.27:/volume1/project     /data;
  sudo mount -t nfs -o proto=tcp,port=2049 192.168.252.27:/volume1/project     /project;
  sudo mount -t nfs -o proto=tcp,port=2049 192.168.252.27:/volume1/tool/ubuntu /tool;
}

# Function to unmount diskstation volumes.
function umount_diskstation {
  sudo umount /home/myusername/Repository;
  sudo umount /media/myusername/diskstation/backup;
  sudo umount /media/myusername/diskstation/download;
  sudo umount /data;
  sudo umount /project;
  sudo umount /tool;
}
```


### Step 06.00: Install basic packages.

#### Step 06.01: Install git.

```bash
sudo apt-get install git git-gui
```

Setup git global settings:

```bash
$ gedit ~/.gitconfig
```

```
[user]
    email = <email-address>
    name =  First Last
[color]
    ui = auto
    diff = auto
    status = auto
    branch = auto
[core]
    safecrlf = true
    whitespace = trailing-space,space-before-tab
[apply]
    whitespace = fix
[push]
    default = simple
[pull]
    rebase = true
[rebase]
    autoStash = true
```

#### Step 06.02: Install meld for performing visual diff.

```bash
sudo apt-get install meld
```

#### Step 06.03: Install cmake for generating cross platform build makefiles.

```bash
sudo apt-get install cmake
```

#### Step 06.04: Install video codecs.

```bash
sudo apt install vlc
sudo apt install ubuntu-restricted-extras
sudo apt install libdvdnav4 libdvdread4 gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libdvd-pkg
```

#### Step 06.05: Install teamviewer to enable remote access for troubleshooting and configuration.

```bash
# add repository key
cd /tmp
wget https://download.teamviewer.com/download/linux/signature/TeamViewer2017.asc
sudo apt-key add TeamViewer2017.asc

# add repository
sudo sh -c 'echo "deb http://linux.teamviewer.com/deb stable main" >> /etc/apt/sources.list.d/teamviewer.list'
sudo sh -c 'echo "deb http://linux.teamviewer.com/deb preview main" >> /etc/apt/sources.list.d/teamviewer.list'

# install
sudo apt update
sudo apt install teamviewer
```

Type the following command to run:
```bash
teamviewer
```


## Technotes

### Installing NVIDIA drivers:

01. https://linuxconfig.org/how-to-install-the-nvidia-drivers-on-ubuntu-18-04-bionic-beaver-linux

### Installing Google Chrome:

01. https://www.linuxbabe.com/ubuntu/install-google-chrome-ubuntu-18-04-lts

### Install Atom Editor:

01. http://tipsonubuntu.com/2016/08/05/install-atom-text-editor-ubuntu-16-04/

### Install Docker:

- [Install Docker CE on Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce)

- [NVIDIA Docker 2.0 - Installation](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)

- [NVIDIA Docker 2.0 - Repository configuration](https://nvidia.github.io/nvidia-docker/)

### Install Intel RealSense Camera Drivers:

- [IntelRealSense - Binary Installation - Linux](https://github.com/IntelRealSense/librealsense/blob/master/doc/distribution_linux.md)

### Install TeamViewer:

- [Installing TeamViewer On Ubuntu 16.04 / 17.10 / 18.04 - Website for Students](https://websiteforstudents.com/installing-teamviewer-on-ubuntu-16-04-17-10-18-04/)

- [2 Ways to Install TeamViewer on Ubuntu 18.04 LTS Bionic Beaver - LinuxBabe](https://www.linuxbabe.com/ubuntu/install-teamviewer-ubuntu-18-04-lts)

### Updating drive mount points:

- [Edit fstab to Auto-Mount Secondary Hard Drives on Linux - Make Tech Easier](https://www.maketecheasier.com/fstab-automount-hard-drive-linux/)

### Setting up an NVMe SSD

- [Setting up an NVMe SSD on Ubuntu 14.04 LTS - Richard's Technotes](https://richardstechnotes.com/2015/12/18/setting-up-an-nvme-ssd-on-ubuntu-14-04-lts/)

- [How To Partition and Format Storage Devices in Linux - Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux)

# Docker images for NVIDIA Vulkan

This repository contains NVIDIA GPU accelerated docker image files for working with the Vulkan SDK:
- [Ubuntu-18.04](./ubuntu/bionic/vulkan-base/)
- [Ubuntu-16.04](./ubuntu/xenial/vulkan-base/)

## Ubuntu Host OS installation

Setup your Ubuntu Host OS, install NVIDIA docker 2 with configure docker user-namespace remapping.
- [Ubuntu-18.04 host installation guide](./doc/ubuntu/ubuntu-18.04-install-myusername.md)


## Running JetBrains IDE from within a docker container

### JetBrains CLion

Follow the [docker setup guide for CLion-2019.1](./doc/jetbrains-clion/docker-setup-clion-2019.1.md) to install CLion to a shared volume mount folder `~/mount/tool/jetbrains/clion-2019.1.4`.

Update `IDE_HOME\bin\idea.properties` to change the default directories for storing
user preferences and plugins.

Update `IDE_HOME\bin\clion64.vmoptions` to change the location of java user
preferences.

Launch the docker container:
```bash
./run.sh
```

Launch CLion:
```bash
developer:~$ /tool/jetbrains/clion-2019.1.4/bin/clion.sh
```

## Volume Sharing

Change permissions recursively for the mount points so that they are accessible
to a non-root user from within the container:
```bash
# use this command for normal ~/mount folder
sudo chmod -R ug+rw ~/mount; sudo chown -R 100999:docker-developer ~/mount;
```

If your `~/mount` folder is symbolically linked to `/mnt/storage/mount`, type the following commands to enable access from the docker container:
```bash
sudo chmod -R ug+rw /mnt/storage/mount; sudo chown -R 100999:docker-developer /mnt/storage/mount;
```

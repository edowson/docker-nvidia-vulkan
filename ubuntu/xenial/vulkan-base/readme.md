# Ubuntu-16.04 LTS Vulkan SDK docker image

## Overview

This docker image has been tested on an Ubuntu-18.04 LTS host running:
- NVIDIA Docker 2
- NVIDIA Driver 430.14

The [./config/vendor/glx_nvidia_icd.json](./config/vendor/glx_nvidia_icd.json) file specifies an `api_version` property:
```json
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path": "libGLX_nvidia.so.0",
        "api_version" : "1.1.99"
    }
}
```

NVIDIA driver 430.14 works with `api_version=1.1.95 and 1.1.99`

## Usage

To build the docker image
```bash
cd ubuntu/xenial/vulkan-base
./build.sh

# list available docker images
docker images
```

To run a docker image
```bash
./run.sh
```

To test vulkan support:
```bash
$ vulkaninfo
```

To test vulkan graphics performance:
```bash
sudo apt update; sudo apt install -y vulkan-utils
vulkan-smoketest
```

**Note:** The Ubuntu-16.04 Vulkan SDK docker image requires the additional installation of the `libxcb-glx0` package, when compared to the Ubuntu-18.04 Vulkan SDK docker image.

## List libraries

List nvidia libraries
```bash
ls -la /usr/lib/x86_64-linux-gnu/*nvidia*
```

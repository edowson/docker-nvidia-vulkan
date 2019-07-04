#!/bin/bash

# common variables
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname $0`

# script variables
HOST_IP=`hostname -I | awk '{print $1}'`
DOCKER_DAEMON_IP=`ip -4 -o a | grep docker0 | awk '{print $4}'`
ORG='edowson'
IMAGE='vulkan-base'
IMAGE_FEATURE='cudagl'
REPOSITORY="$ORG/$IMAGE/$IMAGE_FEATURE"
BUILD_VERSION=${1:-"1.1.108.0"}
CUDA_MAJOR_VERSION='10.1'
CUDNN_VERSION='7.6.1.34'
CONDA_PYTHON_VERSION='3'
CONDA_BASE_PACKAGE='anaconda'
CONDA_VERSION='2019.03'
LLVM_VERSION='7'
NVIDIA_DRIVER_VERSION='430.14'
USER='developer'
USER_ID='1000'
CODE_NAME='bionic'
TAG="$BUILD_VERSION-$CUDA_MAJOR_VERSION-$CODE_NAME"
OPTION=""

# setup pulseaudio cookie
if [ x"$(pax11publish -d)" = x ]; then
    start-pulseaudio-x11;
    echo `pax11publish -d | grep --color=never -Po '(?<=^Cookie: ).*'`
fi

# find a free port
read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
while : ; do
  PULSE_PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`"
  ss -lpn | grep -q ":$PULSE_PORT " || break
done
echo "Using PULSE_PORT=$PULSE_PORT"

# load pulseaudio tcp module
PULSE_MODULE_ID=$(pactl load-module module-native-protocol-tcp port=$PULSE_PORT)
echo "PULSE_MODULE_ID=$PULSE_MODULE_ID"

# run container
xhost +local:root
docker run -it \
  --runtime=nvidia \
  --device /dev/snd \
  -e DISPLAY \
  -e PULSE_SERVER="tcp:$HOST_IP:$PULSE_PORT" \
  -e PULSE_COOKIE_DATA=`pax11publish -d | grep --color=never -Po '(?<=^Cookie: ).*'` \
  -e QT_GRAPHICSSYSTEM=native \
  -e QT_X11_NO_MITSHM=1 \
  -v /dev/shm:/dev/shm \
  -v /etc/localtime:/etc/localtime:ro \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro \
  -v ${XDG_RUNTIME_DIR}/pulse/native:/run/user/1000/pulse/native \
  -v ~/mount/backup:/backup \
  -v ~/mount/data:/data \
  -v ~/mount/project:/project \
  -v ~/mount/tool:/tool \
  --rm \
  --name ${IMAGE}-${TAG} \
  ${REPOSITORY}:${TAG} bash

xhost -local:root

# unload pulseaudio module
pactl unload-module $PULSE_MODULE_ID

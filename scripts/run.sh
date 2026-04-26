#!/usr/bin/env bash
xhost +local:docker > /dev/null

docker run -it --rm \
    --name ros2-test \
    --network=host \
    --ipc=host \
    --gpus all \
    -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $(pwd):/workspace:rw \
    --device /dev/dri \
    -w /workspace \
    ros2-test
#!/usr/bin/env bash
# Start the FAST-LIVO2 container with X11 + GPU passthrough so RViz can render.
#
# Optional env:
#   DATASET_DIR   host path to a ROS2-converted rosbag dir (mounted at /workspace/dataset)
set -euo pipefail

xhost +local:docker > /dev/null

DATASET_MOUNT=()
if [[ -n "${DATASET_DIR:-}" ]]; then
    DATASET_MOUNT=(-v "${DATASET_DIR}:/workspace/dataset:rw")
fi

GPU_ARGS=()
if docker info 2>/dev/null | grep -qi nvidia; then
    GPU_ARGS=(--gpus all -e NVIDIA_DRIVER_CAPABILITIES=all)
fi

docker run -it --rm \
    --name fast-livo2 \
    --network=host \
    --ipc=host \
    "${GPU_ARGS[@]}" \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --device /dev/dri \
    "${DATASET_MOUNT[@]}" \
    -w /workspace \
    fast-livo2:humble

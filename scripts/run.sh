#!/usr/bin/env bash
xhost +local:docker > /dev/null

# Detect host GIDs for /dev/dri devices so the container user can access them
VIDEO_GID=$(getent group video | cut -d: -f3)
RENDER_GID=$(getent group render | cut -d: -f3)

# Bind-mount host PX4-Autopilot if present (run scripts/setup_px4.sh once to clone)
PX4_MOUNT=()
if [[ -d "$(pwd)/PX4-Autopilot" ]]; then
    PX4_MOUNT=(-v "$(pwd)/PX4-Autopilot:/home/ubuntu/PX4-Autopilot:rw")
fi

docker run -it --rm \
    --name ros2-test \
    --network=host \
    --ipc=host \
    --gpus all \
    --group-add "$VIDEO_GID" \
    --group-add "$RENDER_GID" \
    -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility,video,display \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json \
    -e __GLX_VENDOR_LIBRARY_NAME=nvidia \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $(pwd):/workspace:rw \
    "${PX4_MOUNT[@]}" \
    --device /dev/dri \
    -w /workspace \
    ros2-test
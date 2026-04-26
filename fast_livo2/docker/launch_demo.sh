#!/usr/bin/env bash
# Launch FAST-LIVO2 + RViz against a ROS2 rosbag mounted at /workspace/dataset.
# Usage:
#   launch_demo.sh [bag_path]        # bag_path defaults to /workspace/dataset
#   IMG_EN=0 launch_demo.sh          # LiDAR-only (skip visual fusion)
set -eo pipefail
set +u
source /opt/ros/humble/setup.bash
source /workspace/install/setup.bash
set -u

DATASET_ROOT="${1:-/workspace/dataset}"
IMG_EN="${IMG_EN:-1}"
LAUNCH_FILE="${LAUNCH_FILE:-mapping_aviz.launch.py}"

# Find a rosbag2 directory (metadata.yaml + .db3/.mcap) at or under DATASET_ROOT.
META="$(find "${DATASET_ROOT}" -maxdepth 3 -name metadata.yaml -print -quit)"
[[ -z "${META}" ]] && { echo "[launch_demo] No rosbag2 found under ${DATASET_ROOT}" >&2; exit 1; }
BAG_DIR="$(dirname "${META}")"
echo "[launch_demo] Bag: ${BAG_DIR}"

# Auto-detect the image topic from a known candidate list.
IMG_TOPIC=""
TOPICS="$(ros2 bag info "${BAG_DIR}" 2>/dev/null | awk '/Topic:/ {print $2}')"
for c in /image /left_camera/image /camera/image /cam0/image_raw; do
    grep -qx "$c" <<<"$TOPICS" && IMG_TOPIC="$c" && break
done

# Patch a copy of avia.yaml with the detected image topic and IMG_EN flag.
CFG=/tmp/avia_demo.yaml
cp /workspace/install/fast_livo/share/fast_livo/config/avia.yaml "$CFG"
[[ -n "$IMG_TOPIC" ]] && sed -i "s|img_topic:.*|img_topic: \"$IMG_TOPIC\"|" "$CFG"
sed -i "s|img_en:.*|img_en: $IMG_EN|" "$CFG"
echo "[launch_demo] img_en=$IMG_EN img_topic=${IMG_TOPIC:-<default>}"

# fast_livo's image subscriber is RELIABLE (LIVMapper.cpp:267). Force the bag
# publisher's QoS to match so the subscriber accepts the messages.
PLAY_ARGS=("$BAG_DIR")
if [[ -n "$IMG_TOPIC" ]]; then
    QOS=/tmp/qos.yaml
    printf '%s:\n  reliability: reliable\n  history: keep_last\n  depth: 10\n' "$IMG_TOPIC" > "$QOS"
    PLAY_ARGS+=(--qos-profile-overrides-path "$QOS")
fi

trap 'kill $(jobs -p) 2>/dev/null || true' EXIT
ros2 launch fast_livo "$LAUNCH_FILE" use_rviz:=True avia_params_file:="$CFG" &
sleep 4
ros2 bag play "${PLAY_ARGS[@]}" &
wait -n

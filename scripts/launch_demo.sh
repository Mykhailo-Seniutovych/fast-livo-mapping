#!/usr/bin/env bash
# One-shot launch: PX4 SITL + Gazebo + ros_gz bridge + FAST-LIVO2 (with its own rviz).
#
# PX4 (foreground) drops to the pxh> prompt for autopilot interaction.
# Bridge and FAST-LIVO2 run in background with logs at /tmp/*.log.
# Exit pxh (or Ctrl-C) cleans up everything via the trap.
set -e
source /opt/ros/humble/setup.bash
source /home/ubuntu/livo_ws/install/setup.bash

export PX4_GZ_WORLD=forest

trap 'kill $(jobs -p) 2>/dev/null' EXIT

# 1. Bridge — Gazebo sensors → ROS2 topics (RELIABLE QoS so FAST-LIVO2 accepts them)
ros2 run ros_gz_bridge parameter_bridge \
    --ros-args -p config_file:=/workspace/bridge_px4.yaml \
    > /tmp/bridge.log 2>&1 &

sleep 1

# 2. FAST-LIVO2 — subscribes to /lidar/points /imu/data /camera/image (live, no bag).
#    use_rviz:=True launches the bundled fast_livo2.rviz config tuned for its outputs.
ros2 launch fast_livo mapping_aviz.launch.py use_rviz:=True \
    > /tmp/fastlivo.log 2>&1 &

# 3. PX4 SITL — foreground, drops to pxh prompt.
cd /home/ubuntu/PX4-Autopilot
exec make px4_sitl gz_rover_ackermann

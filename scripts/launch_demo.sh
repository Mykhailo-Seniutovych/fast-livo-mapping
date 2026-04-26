#!/usr/bin/env bash
# One-shot launch: PX4 SITL + bridge + rviz, all in this terminal.
#
# PX4 (foreground) brings up Gazebo and drops to the pxh> prompt for direct
# autopilot interaction. Bridge and rviz run in the background with logs at
# /tmp/bridge.log and /tmp/rviz.log. Exit pxh (or Ctrl-C) cleans up everything.
set -e
source /opt/ros/humble/setup.bash

export PX4_GZ_WORLD=forest

trap 'kill $(jobs -p) 2>/dev/null' EXIT

ros2 run ros_gz_bridge parameter_bridge \
    --ros-args -p config_file:=/workspace/bridge_px4.yaml \
    > /tmp/bridge.log 2>&1 &

sleep 1
rviz2 -d /workspace/demo.rviz --ros-args -p use_sim_time:=true \
    > /tmp/rviz.log 2>&1 &

cd /home/ubuntu/PX4-Autopilot
exec make px4_sitl gz_rover_ackermann

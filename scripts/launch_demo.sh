#!/usr/bin/env bash
set -e
source /opt/ros/humble/setup.bash

# Tell Gazebo where to find our local models (so model:// URIs resolve)
export GZ_SIM_RESOURCE_PATH=/workspace/models:$GZ_SIM_RESOURCE_PATH

# Cleanup background processes on exit
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# 1. Gazebo with the forest world + diff-drive vehicle
gz sim -r /workspace/worlds/forest.sdf &
#sleep 3

# 2. The bridge — translates between Gazebo and ROS2 pub/sub
ros2 run ros_gz_bridge parameter_bridge \
    --ros-args -p config_file:=/workspace/bridge.yaml &
sleep 2
#
# 3. rviz2 — uses sim time so timestamps line up with Gazebo
rviz2 -d /workspace/demo.rviz --ros-args -p use_sim_time:=true &
#rviz2 --ros-args -p use_sim_time:=true &

wait
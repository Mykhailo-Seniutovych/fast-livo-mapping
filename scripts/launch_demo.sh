#!/usr/bin/env bash
set -e
source /opt/ros/jazzy/setup.bash

# Cleanup background processes on exit
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# 1. Gazebo with a built-in demo world that has a vehicle + lidar
#    diff_drive.sdf ships with ros_gz_sim demos
gz sim -r /opt/ros/jazzy/share/ros_gz_sim_demos/worlds/vehicle.sdf &
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
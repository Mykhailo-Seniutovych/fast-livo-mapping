#!/usr/bin/env bash
# Bridge + rviz for the PX4 workflow.
#
# Run AFTER `make px4_sitl gz_rover_ackermann` is up in another terminal
# (PX4 launches its own Gazebo). Sensors flow gz → ROS2 via bridge_px4.yaml.
set -e
source /opt/ros/humble/setup.bash

trap 'kill $(jobs -p) 2>/dev/null' EXIT

ros2 run ros_gz_bridge parameter_bridge \
    --ros-args -p config_file:=/workspace/bridge_px4.yaml &
sleep 1

rviz2 -d /workspace/demo.rviz --ros-args -p use_sim_time:=true &
wait

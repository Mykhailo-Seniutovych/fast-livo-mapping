# Description 
This project is a simple integration of [fast_livo2](https://github.com/hku-mars/FAST-LIVO2) library 
with ROS2 project that uses Gazebo and PX4 with a rover and a built in map. 
You can use PX4 to control the rover and fast_livo2 will built a 3D map of the environment in real time 
using camera, lidar and IMU sensor readings. Since the original fast_livo2 uses ROS1, I used [this ROS2 fork](https://github.com/Robotic-Developer-Road/FAST-LIVO2/tree/humble?tab=readme-ov-file#24-vikit) 
instead. 

# Structure
* The project uses [Dockerfile](https://github.com/Mykhailo-Seniutovych/fast-livo-mapping/blob/master/Dockerfile) 
to build and run everything inside a docker container to simplify the dependencies setup, and not clutter your host machine with unnecessary packages.
* The [scripts](https://github.com/Mykhailo-Seniutovych/fast-livo-mapping/tree/master/scripts) folder contains different utility scripts:
  * [build.sh](https://github.com/Mykhailo-Seniutovych/fast-livo-mapping/blob/master/scripts/build.sh) to build the docker image.
  * [run.sh](https://github.com/Mykhailo-Seniutovych/fast-livo-mapping/blob/master/scripts/run.sh) to run the image.
  * [launch_demo.sh](https://github.com/Mykhailo-Seniutovych/fast-livo-mapping/blob/master/scripts/launch_demo.sh) 
  this script is run from whithin the docker container and launches everything - gazebo, PX4 bridge and fast_livo2 node
* The [PX4 overrides](https://github.com/Mykhailo-Seniutovych/fast-livo-mapping/tree/master/px4_overrides/Tools/simulation/gz) folder contains model of the rover
of the rover with a camera and lidar sensors setup and forest map with a ground plane. It's called overrides because the SDF files were copied from PX4 repository
 and slightly modified.

# Local Run
_The project was developed and tested on Ubuntu 24 host with NVIDIA GPU, I cannot guarantee it will run correctly on a system with another GPU._
To run the project locally execute the following steps:
* Build the image - `./scripts/build.sh`
* Run the docker container - `./scripts/run.sh`
* Inside docker container run - `./scripts/launch_demo.sh`. You should see the Gazebo UI running and RViz loaded.
* Install [QGroundControl](https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl-x86_64.AppImage) if you don't have it already (a UI app that connects to PX4 SITL)
* Run QGroundControl, run it, connect to the rover and control it (e.g. plan some mission)
* See the map being built in real time

# DEMO
__Checkout the [Demo Video](https://drive.google.com/file/d/1_tn7miBXMDTaBsQcF5r-_LQeAzhGwM8L/view?usp=sharing) of how I run this project locally__

# Note
This is not a production ready solution. The project was developed quickly in a little over one day just 
to integrate everything together and make it functional. There are some issues:
* fast_livo2 is just a folder that was copied from a github project. In real setting I would consider making it a submodule.
* PX4 is cloned and built directly in the Dockerfile, so it's not even visible in the project structure, in real settings I would consider making it a submodule too.
* launch_demo.sh compiles PX4 libs, in real settings I would put it in a separate build/compilation script. 
* A lot of code was generated using AI tools to speed up the assignment completion. The scripts would need some cleanup and a better structure (e.g. Dockerfile).


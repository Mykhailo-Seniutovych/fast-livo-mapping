FROM osrf/ros:humble-desktop-full

# System packages: Gazebo Harmonic, ros_gz bridge, rviz, FAST-LIVO2 build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        gnupg \
        git \
        wget \
        ca-certificates \
        lsb-release \
        pkg-config \
        mesa-utils \
        libgl1-mesa-dri \
        ros-humble-rviz2 \
        ros-humble-rviz-imu-plugin \
        libpcl-dev \
        libeigen3-dev \
        libopencv-dev \
        libfmt-dev \
        libboost-all-dev \
        libgoogle-glog-dev \
        libyaml-cpp-dev \
        ros-humble-pcl-ros \
        ros-humble-pcl-conversions \
        ros-humble-cv-bridge \
        ros-humble-image-transport \
        ros-humble-tf2-ros \
        ros-humble-topic-tools \
        ros-humble-rosbag2 \
        ros-humble-rosbag2-storage-mcap \
        python3-colcon-common-extensions \
        python3-rosdep \
        python3-vcstool \
    && curl https://packages.osrfoundation.org/gazebo.gpg \
        --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        gz-harmonic \
        ros-humble-ros-gzharmonic \
    && rm -rf /var/lib/apt/lists/*

# Livox-SDK2 (runtime dep of livox_ros_driver2)
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git /tmp/Livox-SDK2 \
 && cmake -S /tmp/Livox-SDK2 -B /tmp/Livox-SDK2/build \
 && cmake --build /tmp/Livox-SDK2/build -j"$(nproc)" \
 && cmake --install /tmp/Livox-SDK2/build \
 && ldconfig \
 && rm -rf /tmp/Livox-SDK2

# Sophus 1.22.10
RUN git clone https://github.com/strasdat/Sophus.git /tmp/Sophus \
 && cd /tmp/Sophus && git checkout 1.22.10 \
 && cmake -S /tmp/Sophus -B /tmp/Sophus/build \
        -DBUILD_SOPHUS_TESTS=OFF \
        -DBUILD_SOPHUS_EXAMPLES=OFF \
        -DSOPHUS_USE_BASIC_LOGGING=ON \
 && cmake --build /tmp/Sophus/build -j"$(nproc)" \
 && cmake --install /tmp/Sophus/build \
 && rm -rf /tmp/Sophus

# vikit_common's CMakeLists uses the variable-style API (Sophus_INCLUDE_DIRS) but
RUN mkdir -p /usr/local/share/sophus/cmake && \
    printf '%s\n' \
        'set(Sophus_INCLUDE_DIRS "/usr/local/include")' \
        'set(Sophus_INCLUDE_DIR  "/usr/local/include")' \
        'set(Sophus_LIBRARIES    "")' \
        'set(Sophus_LIBS         "")' \
        'set(Sophus_FOUND TRUE)' \
        'if(NOT TARGET Sophus::Sophus)' \
        '    add_library(Sophus::Sophus INTERFACE IMPORTED)' \
        '    set_target_properties(Sophus::Sophus PROPERTIES' \
        '        INTERFACE_INCLUDE_DIRECTORIES "/usr/local/include")' \
        'endif()' \
        > /usr/local/share/sophus/cmake/SophusConfig.cmake

# Non-root user (matches host UID/GID 1000)
RUN groupadd --gid 1000 ubuntu \
 && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash ubuntu \
 && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ubuntu
WORKDIR /home/ubuntu
ENV PATH=/home/ubuntu/.local/bin:$PATH

# PX4-Autopilot clone + dep setup
RUN git clone --recursive https://github.com/PX4/PX4-Autopilot.git /home/ubuntu/PX4-Autopilot \
 && bash /home/ubuntu/PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx --no-sim-tools \
 && sudo rm -rf /var/lib/apt/lists/*

# FAST-LIVO2 colcon workspace at /home/ubuntu/livo_ws 
RUN mkdir -p /home/ubuntu/livo_ws/src \
 && git clone https://github.com/Robotic-Developer-Road/rpg_vikit.git \
        /home/ubuntu/livo_ws/src/rpg_vikit \
 && git clone https://github.com/Livox-SDK/livox_ros_driver2.git \
        /home/ubuntu/livo_ws/src/livox_ros_driver2 \
 && cd /home/ubuntu/livo_ws/src/livox_ros_driver2 \
 && cp -f package_ROS2.xml package.xml \
 && cp -rf launch_ROS2 launch

# Copy FAST-LIVO2 source into the workspace and build everything.
COPY --chown=ubuntu:ubuntu fast_livo2/ /home/ubuntu/livo_ws/src/FAST-LIVO2/

RUN bash -c "source /opt/ros/humble/setup.bash \
 && cd /home/ubuntu/livo_ws \
 && colcon build --symlink-install --continue-on-error \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DROS_EDITION=ROS2 -DDISTRO_ROS=humble \
 && test -x /home/ubuntu/livo_ws/install/fast_livo/lib/fast_livo/fastlivo_mapping"

# PX4 overrides 
COPY --chown=ubuntu:ubuntu px4_overrides/ /home/ubuntu/px4_overrides_staging/
RUN cp -r /home/ubuntu/px4_overrides_staging/. /home/ubuntu/PX4-Autopilot/ \
 && rm -rf /home/ubuntu/px4_overrides_staging

# Shell defaults
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc \
 && echo "source /home/ubuntu/livo_ws/install/setup.bash" >> ~/.bashrc

CMD ["/bin/bash"]

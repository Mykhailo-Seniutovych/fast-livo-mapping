FROM osrf/ros:humble-desktop-full

ARG DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble
SHELL ["/bin/bash", "-c"]

# System + ROS dependencies covering README sections 2.1 - 2.5
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        git \
        wget \
        curl \
        ca-certificates \
        build-essential \
        cmake \
        pkg-config \
        python3-pip \
        python3-colcon-common-extensions \
        python3-rosdep \
        python3-vcstool \
        mesa-utils \
        libgl1-mesa-dri \
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
        ros-humble-rviz2 \
        ros-humble-demo-nodes-cpp \
        ros-humble-topic-tools \
        ros-humble-rosbag2 \
        ros-humble-rosbag2-storage-mcap \
    && rm -rf /var/lib/apt/lists/*

# rosbags lets us convert ROS1 bags (e.g. Retail_Street.bag) to ROS2 format
RUN pip3 install --no-cache-dir rosbags

# Build & install Livox-SDK2 (runtime dependency of livox_ros_driver2)
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git /tmp/Livox-SDK2 \
    && cmake -S /tmp/Livox-SDK2 -B /tmp/Livox-SDK2/build \
    && cmake --build /tmp/Livox-SDK2/build -j"$(nproc)" \
    && cmake --install /tmp/Livox-SDK2/build \
    && ldconfig \
    && rm -rf /tmp/Livox-SDK2

# Build & install Sophus from source.
# README §2.3 suggests commit a621ff, but that revision installs only .h headers
# while rpg_vikit's vikit_common (and fast_livo itself) include <sophus/se3.hpp>
# from the templated API. Tag 1.22.10 is header-only and ships the .hpp headers
# at /usr/local/include/sophus/*.
RUN git clone https://github.com/strasdat/Sophus.git /tmp/Sophus \
    && cd /tmp/Sophus \
    && git checkout 1.22.10 \
    && cmake -S /tmp/Sophus -B /tmp/Sophus/build \
        -DBUILD_SOPHUS_TESTS=OFF \
        -DBUILD_SOPHUS_EXAMPLES=OFF \
        -DSOPHUS_USE_BASIC_LOGGING=ON \
    && cmake --build /tmp/Sophus/build -j"$(nproc)" \
    && cmake --install /tmp/Sophus/build \
    && rm -rf /tmp/Sophus

# Sophus 1.22.10 ships its own SophusConfig.cmake (target-based: Sophus::Sophus),
# but vikit_common's CMakeLists uses the older variable-based API
# (INCLUDE_DIRECTORIES(${Sophus_INCLUDE_DIRS})). Overwrite the installed config
# with a minimal one that exports both styles so either consumer works.
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

# Set up the colcon workspace
WORKDIR /workspace
RUN mkdir -p /workspace/src

# rpg_vikit (camera models + math used by FAST-LIVO2)
RUN git clone https://github.com/Robotic-Developer-Road/rpg_vikit.git /workspace/src/rpg_vikit

# livox_ros_driver2 — uses CustomMsg consumed by FAST-LIVO2.
# Its CMakeLists.txt branches on -DROS_EDITION; we just need to swap in the ROS2
# package.xml and launch directory (mirrors what the repo's build.sh does for humble).
RUN git clone https://github.com/Livox-SDK/livox_ros_driver2.git /workspace/src/livox_ros_driver2 \
    && cd /workspace/src/livox_ros_driver2 \
    && cp -f package_ROS2.xml package.xml \
    && cp -rf launch_ROS2 launch

# Copy FAST-LIVO2 source from the build context.
# The hardcoded link path in fast_livo's CMakeLists (../../install/vikit_*) requires
# this exact layout: <ws>/src/FAST-LIVO2 + <ws>/install/...
COPY . /workspace/src/FAST-LIVO2

# Build the entire workspace. --continue-on-error mirrors the README guidance,
# but we then assert the main binary exists so a real failure isn't masked.
RUN source /opt/ros/humble/setup.bash \
    && cd /workspace \
    && colcon build --symlink-install --continue-on-error \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DROS_EDITION=ROS2 -DDISTRO_ROS=humble \
    && test -x /workspace/install/fast_livo/lib/fast_livo/fastlivo_mapping

# Auto-source ROS + workspace overlay for any interactive shell
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc \
    && echo "source /workspace/install/setup.bash" >> /root/.bashrc

# Make the in-container demo launcher available on PATH
COPY docker/launch_demo.sh /usr/local/bin/launch_demo.sh
RUN chmod +x /usr/local/bin/launch_demo.sh

WORKDIR /workspace
CMD ["/bin/bash"]

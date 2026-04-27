FROM osrf/ros:humble-desktop-full

# Install Gazebo Harmonic (not in default Humble repos) via OSRF apt repo,
# plus the matching ros_gz bridge.
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    gnupg \
    git \
    lsb-release \
    mesa-utils \
    libgl1-mesa-dri \
    ros-humble-rviz2 \
    ros-humble-rviz-imu-plugin \
    && curl https://packages.osrfoundation.org/gazebo.gpg \
        --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        gz-harmonic \
        ros-humble-ros-gzharmonic \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user matching host UID/GID 1000 (Humble image lacks `ubuntu` by default)
RUN groupadd --gid 1000 ubuntu \
 && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash ubuntu \
 && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ubuntu
WORKDIR /home/ubuntu

# Add ~/.local/bin to PATH so pip-installed scripts (kconfig, nunavut, …) are
# findable when PX4's `make` invokes them.
ENV PATH=/home/ubuntu/.local/bin:$PATH

# Clone PX4-Autopilot into the image and run its own setup script for build
# deps (apt + pip). --no-nuttx skips the embedded toolchain we don't need;
# --no-sim-tools skips Gazebo install (we already have Harmonic above).
RUN git clone --recursive https://github.com/PX4/PX4-Autopilot.git /home/ubuntu/PX4-Autopilot \
 && bash /home/ubuntu/PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx --no-sim-tools \
 && sudo rm -rf /var/lib/apt/lists/*

# Apply our overrides (camera + lidar on rover, ground plane in forest world).
# COPY happens late so editing px4_overrides/ doesn't invalidate the heavy
# upstream apt/pip layers above — only the small override layer rebuilds.
COPY --chown=ubuntu:ubuntu px4_overrides/ /home/ubuntu/px4_overrides_staging/
RUN cp -r /home/ubuntu/px4_overrides_staging/. /home/ubuntu/PX4-Autopilot/ \
 && rm -rf /home/ubuntu/px4_overrides_staging

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

CMD ["/bin/bash"]

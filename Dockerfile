FROM osrf/ros:humble-desktop-full

# Install Gazebo Harmonic (not in default Humble repos) via OSRF apt repo,
# plus the matching ros_gz bridge.
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    gnupg \
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

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

CMD ["/bin/bash"]

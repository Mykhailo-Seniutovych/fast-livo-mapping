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

# PX4's setup script installs tools to ~/.local/bin via pip; PX4's make calls
# kconfig/nunavut from there, so ensure it's on PATH for all shells.
ENV PATH=/home/ubuntu/.local/bin:$PATH

# Install PX4 build dependencies. We clone PX4-Autopilot to /tmp purely to run
# its setup script (which only installs apt + pip packages and is idempotent),
# then remove the source. Users bind-mount their own host clone at runtime,
# so build artifacts persist across container restarts.
RUN git clone --depth 1 https://github.com/PX4/PX4-Autopilot.git /tmp/px4-setup \
 && bash /tmp/px4-setup/Tools/setup/ubuntu.sh --no-nuttx --no-sim-tools \
 && rm -rf /tmp/px4-setup \
 && sudo rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

CMD ["/bin/bash"]

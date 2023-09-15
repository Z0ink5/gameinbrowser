# Use a base image that supports Nvidia GPU passthrough and has Steam dependencies
FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Set ENV variables for docker
ENV \
    NVIDIA_DRIVER_CAPABILITIES="all" \
    NVIDIA_VISIBLE_DEVICES="all"


# Update and install necessary packages
echo "**** Step 1: Update and install necessary packages ****"
RUN apt-get update && \
    apt-get install -y \
    wget \
    software-properties-common \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    mesa-utils \
    xvfb \
    x11vnc \
    pulseaudio \
    fluxbox \
    unzip \
    zenity \
    curl


#       Anything only required for Intel/AMD/NVIDIA should go in the container init.
RUN \
    echo "**** Step 2: Update apt database ****" \
        && dpkg --add-architecture i386 \
        && apt-get update \
    && \
    echo "**** Step 3: Install mesa requirements ****" \
        && apt-get install -y --no-install-recommends \
            libgl1-mesa-dri \
            libgl1-mesa-glx \
            libgles2-mesa \
            libglu1-mesa \
            mesa-utils \
            mesa-utils-extra \
    && \
    echo "****  Step 4: Install vulkan requirements ****" \
        && apt-get install -y --no-install-recommends \
            libvulkan1 \
            libvulkan1:i386 \
            mesa-vulkan-drivers \
            mesa-vulkan-drivers:i386 \
            vulkan-tools \
    && \
    echo "****  Step 5: Install desktop requirements ****" \
        && apt-get install -y --no-install-recommends \
            libdbus-1-3 \
            libegl1 \
            libgtk-3-0 \
            libgtk2.0-0 \
            libsdl2-2.0-0 \
    && \
    echo "****  Step 6: Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Create a custom folder for Steam installation and configure it
RUN mkdir -p /opt/steam && \
    cd /opt/steam && \
    useradd -m steamuser && \
    chown -R steamuser:steamuser /opt/steam && \
    su - steamuser -c "steam"


# Download and install the latest Nvidia drivers
echo "**** NVIDIA DRIVERS SETUP ****"
RUN apt-get update && \
    apt-get install -y \
    wget \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Download the latest Nvidia driver
RUN wget http://us.download.nvidia.com/XFree86/Linux-x86_64/$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | tr -d ' ')/NVIDIA-Linux-x86_64-$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | tr -d ' ').run -O /tmp/nvidia-driver.run

# Make the Nvidia driver installation script executable
RUN chmod +x /tmp/nvidia-driver.run

# Install the Nvidia driver silently (replace "--no-kernel-module" with your desired options)
RUN /tmp/nvidia-driver.run --silent --no-kernel-module --installpath=/usr --dkms --disable-nouveau

# Download and install Steam
echo "**** Installing Steam *****"
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steam.deb && \
    dpkg -i steam.deb

# Install Proton (modify this part based on the Proton version you need)
echo "**** Installing Proton 8.0.3c ****"
RUN mkdir -p /opt/proton && \
    cd /opt/proton && \
    wget https://github.com/ValveSoftware/Proton/archive/refs/tags/proton-8.0-3c.tar.gz && \
    tar xzf proton-8.0-3c.tar.gz && \
    rm proton-8.0-3c.tar.gz

# Set up KasmVNC (modify this part based on your KasmVNC setup)
echo "**** Downloading and installing KasmVNC 1.2.0 ****"
RUN wget https://github.com/kasmtech/KasmVNC/releases/download/v1.2.0/kasmvncserver_focal_1.2.0_amd64.deb && \
    dpkg -i kasmvncserver_focal_1.2.0_amd64.deb
    sudo addgroup steamuser ssl-cert

# Copy the kasmvnc config file to proper folder
COPY ./kasmvnc.yml /etc/kasmvnc/kasmvnc.yaml

# Create a persistent path for game data
VOLUME /mnt/SteamGames

# Set up your gaming environment, configure Steam, and ProtonQT as needed

# Expose necessary ports for KasmVNC and other services
EXPOSE 8083

# Start your gaming and streaming services here (e.g., Steam, ProtonQT, and KasmVNC)
# Startup of KasmVNC

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./
RUN chmod +x /entrypoint.sh
# Start the entry point script (customize as needed)
CMD ["./entrypoint.sh"]

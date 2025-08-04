FROM ubuntu:22.04

# Install base tools and Shadowsocks
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    obfs4proxy \ 
    python3 \
    python3-pip \
    tshark \
    iputils-ping \
    net-tools \
    curl \
    git \
    build-essential \
    shadowsocks-libev \
    sudo \
    psmisc \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone your repo
RUN git clone --branch min_size_research https://github.com/Nob1K/FEP_research.git .
RUN pip install ptadapter

# Copy local proxy startup scripts into the cloned repo
COPY client-proxy-ss server-proxy-ss ./datastream-experiments/

# Make all necessary scripts/binaries executable
# This must target files *inside* the repo (i.e., in ./datastream-experiments)
RUN chmod +x ./datastream-experiments/setup \
             ./datastream-experiments/client \
             ./datastream-experiments/server \
             ./datastream-experiments/mitm.py \
             ./datastream-experiments/extractFin.py \
             ./datastream-experiments/*.sh \
             ./datastream-experiments/client-proxy-ss \
             ./datastream-experiments/server-proxy-ss

# Optional default command
# CMD ["./datastream-experiments/runtest.sh"]
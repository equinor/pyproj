
# Dev container for pyproj development (Debian-based for apt support)
ARG VARIANT=3.13
FROM mcr.microsoft.com/devcontainers/python:${VARIANT}

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies for building PROJ & pyproj (include sudo)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       pkg-config \
       curl \
       ca-certificates \
       git \
    git-lfs \
       cmake \
       ninja-build \
       libsqlite3-dev \
       libtiff-dev \
       libjpeg-dev \
       libcurl4-openssl-dev \
       libproj-dev \
       proj-bin \
       proj-data \
       bash-completion \
      sudo \
    && rm -rf /var/lib/apt/lists/*

# # Ensure vscode user (provided by base image) has passwordless sudo
# RUN echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-vscode-nopasswd \
#    && chmod 0440 /etc/sudoers.d/99-vscode-nopasswd

WORKDIR /workspaces/pyproj

SHELL ["/bin/bash", "-c"]

# Upgrade pip & install wheel/cython early (cached layer)
RUN python -m pip install --upgrade pip setuptools wheel cython

# Display versions (build log clarity)
RUN echo "Python version:" $(python -V) \
 && echo "PROJ version:" $(proj 2>/dev/null | head -n1 || true) \
 && echo "projinfo test:" $(projinfo EPSG:4326 2>/dev/null | head -n1 || true)


# Ensure pyproj build finds system PROJ (multi-arch on Debian/Ubuntu)
ENV PROJ_DIR=/usr
ENV PROJ_INCDIR=/usr/include
ENV PROJ_LIBDIR=/usr/lib/x86_64-linux-gnu


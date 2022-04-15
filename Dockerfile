FROM debian:bullseye as osxcross

# Build osxcross using MacOS 12.3 SDK
RUN apt update && \
    apt install -y \
        clang \
        cmake \
        gcc \
        git \
        git-lfs \
        g++ \
        zlib1g-dev \
        libmpc-dev \
        libmpfr-dev \
        libgmp-dev \
        libssl-dev \
        libxml2-dev \
        wget \
        xz-utils && \
    git clone https://github.com/ilch1/osxcross && \
    cd osxcross && \
    git lfs install && \
    git lfs fetch --all && \
    git lfs pull && \
    TARGET_DIR=/usr/local/osxcross UNATTENDED=yes OSX_VERSION_MIN=10.9 ./build.sh

FROM rust:1.60.0

# Copy osxcross build output
COPY --from=osxcross /usr/local/osxcross /usr/local/osxcross

# Install mingw-64 for cross-compiling to Windows
# Install clang for cross compiling to macOS
#
# Set global cargo configugration which will be merged with other cargo configugations
# https://doc.rust-lang.org/stable/cargo/reference/config.html#hierarchical-structure
RUN apt update && \
    apt install -y \
        mingw-w64 \
        clang && \
    rustup target add x86_64-unknown-linux-musl && \
    rustup target add x86_64-apple-darwin && \
    rustup target add x86_64-pc-windows-gnu && \
    mkdir /.cargo && \
    echo '[target.x86_64-apple-darwin]' >> /.cargo/config.toml && \
    echo 'linker = "/usr/local/osxcross/bin/x86_64-apple-darwin21.4-clang"' >> /.cargo/config.toml && \
    echo 'ar = "/usr/local/osxcross/bin/x86_64-apple-darwin21.4-ar"' >> /.cargo/config.toml

# Update path to include osxcross binaries
ENV PATH=$PATH:/usr/local/osxcross/bin


# ====================== BASE STAGE ======================
ARG COMPILER
ARG RHEL_VERSION
FROM registry.redhat.io/ubi${RHEL_VERSION%.*}/ubi:${RHEL_VERSION} AS base
ARG RHEL_VERSION
ARG MINIMUM_CLANG_VERSION=16
ARG CONAN_REMOTE=https://conan.ripplex.io
ARG PYTHON_VERSION=3.12
ARG COMPILER_VERSION
ARG COMPILER

# Use Bash as the default shell for RUN commands, using the options
# `set -o errexit -o pipefail`, and as the entrypoint.
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
WORKDIR /root

# Update the packages installed on the system.
RUN dnf update-minimal -y --security --sec-severity=Important --sec-severity=Critical

# Install tools that are shared by all stages.
RUN --mount=type=tmpfs,target=/var/cache/dnf/ <<EOF
pkgs=()
pkgs+=(ca-certificates)  # Enable TLS verification for HTTPS connections by providing trusted root certificates.
pkgs+=(cmake)            # Required build tool.
pkgs+=(file)             # Required packaging tool.
pkgs+=(git)              # Required build tool.
pkgs+=(gpg)              # Dependency for tools requiring signing or encrypting/decrypting.
pkgs+=(gnupg2)           # Dependency for tools requiring signing or encrypting/decrypting.
pkgs+=(jq)               # JSON manipulation.
pkgs+=(libstdc++-static) # Required to statically link libraries into xrpld.
pkgs+=(ninja-build)      # Required build tool.
pkgs+=(perl-FindBin)     # Required to compile OpenSSL.
pkgs+=(python${PYTHON_VERSION})       # Required build tool.
pkgs+=(python${PYTHON_VERSION}-pip)   # Package manager for Python applications.
pkgs+=(python3-jinja2)   # Required build tool. #NOTE: @mml Really required?
pkgs+=(rpm-build)        # Required packaging tool.
pkgs+=(rpmdevtools)      # Required packaging tool.
pkgs+=(vim)              # Text editor.
pkgs+=(wget)             # Required build tool.
dnf install -y --allowerasing --setopt=tsflags=nodocs "${pkgs[@]}"
dnf clean -y all
EOF

# Add symlinks to point to the latest Python versions. The /usr/local/bin
# directory is in the PATH before the /usr/bin directory, so the new Python
# versions will be used by default.
# NOTE: @mml Stuff is in lib64
## python3.9 -c 'import sys; print(sys.path)'
#['', '/usr/lib64/python39.zip', '/usr/lib64/python3.9', '/usr/lib64/python3.9/lib-dynload', '/usr/lib64/python3.9/site-packages', '/usr/lib/python3.9/site-packages']
## python3.12 -c 'import sys; print(sys.path)'
#['', '/usr/lib64/python312.zip', '/usr/lib64/python3.12', '/usr/lib64/python3.12/lib-dynload', '/usr/lib64/python3.12/site-packages', '/usr/lib/python3.12/site-packages']
RUN <<EOF
#mkdir -p /usr/local/bin
ln -sf /usr/bin/python3.12 /usr/local/bin/python3
# ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3
ln -sf /usr/bin/python3.12 /usr/local/bin/python
# ln -sf /usr/bin/python3 /usr/local/bin/python
ln -sf /usr/bin/pydoc3.12 /usr/local/bin/pydoc3
# ln -sf /usr/bin/pydoc${PYTHON_VERSION} /usr/local/bin/pydoc3
ln -sf /usr/bin/pydoc3.12 /usr/local/bin/pydoc
# ln -sf /usr/bin/pydoc3 /usr/local/bin/pydoc
ln -sf /usr/bin/pip3.12 /usr/local/bin/pip3
# ln -sf /usr/bin/pip${PYTHON_VERSION} /usr/local/bin/pip3
ln -sf /usr/bin/pip3.12 /usr/local/bin/pip
# ln -sf /usr/bin/pip3 /usr/local/bin/pip

mkdir -p /usr/local/lib
ln -sf /usr/lib/python${PYTHON_VERSION} /usr/local/lib/python${PYTHON_VERSION}
EOF

# Install Python-based tools.
ARG CONAN_VERSION
ARG GCOVR_VERSION
RUN pip install --no-cache conan==${CONAN_VERSION} gcovr==${GCOVR_VERSION}
COPY <<EOF .conan2/global.conf
tools.build:compiler_executables={'c': '{{ os.getenv("CC")}}', 'cpp': '{{ os.getenv("CXX")}}'}
user.package:distro="rhel-${RHEL_VERSION}"
tools.info.package_id:confs=["user.package:distro"]
EOF

# ====================== GCC STAGE ======================
FROM base AS gcc

RUN <<EOF
dnf remove -y gcc gcc-c++
dnf install -y --setopt=tsflags=nodocs gcc-toolset-${COMPILER_VERSION}-gcc gcc-toolset-${COMPILER_VERSION}-gcc-c++
dnf clean -y all
rm -rf /var/cache/dnf/*
update-alternatives \
  --install /usr/bin/cc cc /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/gcc 999
update-alternatives \
  --install /usr/bin/c++ c++ /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/g++ 999
update-alternatives \
  --install /usr/bin/gcc gcc /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/gcc 100 \
  --slave /usr/bin/g++ g++ /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/g++ \
  --slave /usr/bin/cpp cpp /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/cpp \
  --slave /usr/bin/gcov gcov /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/gcov \
  --slave /usr/bin/gcov-dump gcov-dump /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/gcov-dump-${COMPILER_VERSION} \
  --slave /usr/bin/gcov-tool gcov-tool /opt/rh/gcc-toolset-${COMPILER_VERSION}/root/usr/bin/gcov-tool-${COMPILER_VERSION}
update-alternatives --auto cc
update-alternatives --auto c++
update-alternatives --auto gcc
EOF

# Set the compiler environment variables to point to the GCC binaries.
ENV CC=/usr/bin/gcc \
    CXX=/usr/bin/g++

# ===================== CLANG STAGE =====================
FROM base AS clang

# Install Clang. Note that in the RHEL UBIs, we cannot choose the Clang version
# to install and we get what is available. Some build dependencies require GCC
# to be also available.
RUN <<EOF
dnf install -y --setopt=tsflags=nodocs clang llvm gcc gcc-c++
dnf clean -y all
rm -rf /var/cache/dnf/*
update-alternatives \
  --install /usr/bin/cc cc /usr/bin/clang 999
update-alternatives \
  --install /usr/bin/c++ c++ /usr/bin/clang++ 999
update-alternatives --auto cc
update-alternatives --auto c++
EOF

ENV CC=/usr/bin/clang \
    CXX=/usr/bin/clang++

# ===================== COMPILER IMAGE =====================
FROM $COMPILER

# Check that the installed compiler is what we expect.
RUN <<EOF
set -x
comparison='!='
msg="does not match expected version"
if [ "${COMPILER}" = "clang" ]; then
  COMPILER_VERSION="${MINIMUM_CLANG_VERSION}"
  msg="is less than minimum ${COMPILER} version required"
  comparison="-lt"
fi

CC_VER=$(${CC} -dumpversion)
CC_VER=${CC_VER%%.*}
if [ "${CC_VER}" "${comparison}" "${COMPILER_VERSION}" ]; then
  echo "ERROR: '${CC} -dumpversion' gives '${CC_VER}', which ${msg} '${COMPILER_VERSION}'."
  exit 1
fi
CXX_VER=$(${CXX} -dumpversion)
CXX_VER=${CXX_VER%%.*}
if [ "${CXX_VER}" "${comparison}" "${COMPILER_VERSION}" ]; then
  echo "ERROR: ${CXX} -dumpversion gives '${CXX_VER}', which ${msg} '${COMPILER_VERSION}'."
  exit 1
fi
EOF

# Configure Conan
# Create a default Conan profile.
RUN --mount=type=tmpfs,target=/tmp <<EOF
  set -euo pipefail
  conan profile detect
EOF
# Add the XRP Ledger Foundation's Conan remote
RUN --mount=type=tmpfs,target=/tmp <<EOF
  conan remote add --index 0 xrplf "${CONAN_REMOTE}"
EOF

# Print the Conan profile to verify the configuration.
RUN <<EOF
  conan profile show
  conan config show "core*"
  conan remote list
EOF

# Test the image by compiling a simple C++ program.
RUN --mount=type=bind,source=test,target=test_src \
    --mount=type=tmpfs,target=test_bld \
<<EOF
  export CONAN_HOME=~/test_bld
  conan config install .conan2
  cp -r test_src/* test_bld
  cd test_bld
  ./run.sh "${CC}"
EOF

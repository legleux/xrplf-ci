#!/bin/bash

set -ex
set -o pipefail

# Install Conan dependencies, configure the project, and build the executable.
conan install . --output-folder=build --build=missing
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build .

# Run the executable.
./example | grep -E "^Compiler used: $(basename $1)$"

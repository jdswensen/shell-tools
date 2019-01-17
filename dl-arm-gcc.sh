#!/usr/bin/env bash

set -e

script_name=$(basename "$0")
script_dir="$( cd "$(dirname "$0")" ; pwd -P )"

# shellcheck source=/dev/null
source "${script_dir}/common"

GCC_ARM_LINK="https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm"

V8_2018_Q4_DIR_STR="8-2018q4"
V8_2018_Q4_STR="8-2018-q4-major"

V7_2018_Q2_DIR_STR="7-2018q2"
V7_2018_Q2_STR="7-2018-q2"

DIR_STR="${V8_2018_Q4_DIR_STR}"
VER_STR="${V8_2018_Q4_STR}"
LINUX_GCC_ARM="/${DIR_STR}/gcc-arm-none-eabi-${VER_STR}-linux.tar.bz2"
MAC_GCC_ARM="/${DIR_STR}/gcc-arm-none-eabi-${VER_STR}-mac.tar.bz2"

DL_DESTINATION="${HOME}/Downloads"
DL_FILENAME="gcc-arm-none-eabi"

if [ "$(st_is_os "Linux")" = "true" ]; then
    DL="${GCC_ARM_LINK}${LINUX_GCC_ARM}"
else
    DL="${GCC_ARM_LINK}${MAC_GCC_ARM}"
fi

if [ ! -f "${DL_DESTINATION}/gcc-arm-none-eabi.tar.bz2" ]; then
    #curl "${DL}" --output ${DL_DESTINATION}/gcc-arm-none-eabi.tar.bz2 --silent
    wget --quiet -c -O "${DL_DESTINATION}/gcc-arm-none-eabi.tar.bz2" "${DL}"
fi

mkdir -p "${HOME}/opt/"
if [ ! -d "${HOME}/opt/gcc-arm-none-eabi-${VER_STR}" ]; then
    tar -xjf "${DL_DESTINATION}/gcc-arm-none-eabi.tar.bz2" -C "${HOME}/opt/"
    ln -s "${HOME}/opt/gcc-arm-none-eabi-${VER_STR}" "${HOME}/opt/gcc-arm-none-eabi"
fi

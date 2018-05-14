#!/usr/bin/env bash

set -e

build_dir="."

BUILD_WRAPPER_DL_BASE="https://sonarcloud.io/static/cpp"
BUILD_WRAPPER_DL_LINUX="build-wrapper-linux-x86.zip"
BUILD_WRAPPER_DL_MACOS="build-wrapper-macosx-x86.zip"

BUILD_WRAPPER_LINUX_CMD="build-wrapper-linux-x86-64"
BUILD_WRAPPER_MACOS_CMD="build-wrapper-macosx-x86"

script_name=$(basename "$0")
script_dir="$( cd "$(dirname "$0")" ; pwd -P )"

# shellcheck source=/dev/null
source "${script_dir}/common"

usage() {
    printf "usage: %s [OPTS]\\n" "${script_name}"
    printf "OPTS:\\n"
    printf "    -b | --build-dir                Directory to build in\\n"
    printf "    -c | --cmake-dir                CMake configuration location\\n"
    printf "    -t | --travis                   Build using the travis build system\\n"
    printf "    -v | --verbose                  Verbose output"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "${1}" in
        -b|--build-dir) cli_build_dir="${2}"; shift ;;
        -c|--cmake-dir) cli_cmake="yes"; cli_cmake_dir="${2}"; shift ;;
        -t|--travis) cli_travis="yes";;
        -v|--verbose) cli_verbose="yes";;
        -h*|--help*|*) usage ;;
    esac
    shift
done


if [[ ${cli_verbose} == "yes" ]]; then
    set -x
fi

if [[ -n ${cli_build_dir} ]]; then
    build_dir=${cli_build_dir};
    printf "build dir: %s\\n" "${build_dir}"
fi

check_depends() {
    st_require_command unzip
    st_require_command sonar-scanner
}

get_build_wrapper(){

    if [ "$(st_is_os "Linux")" == "true" ]; then
        printf "System is Linux\\n"
        BUILD_WRAPPER_DL_URL="${BUILD_WRAPPER_DL_BASE}/${BUILD_WRAPPER_DL_LINUX}"
        BUILD_WRAPPER_DL_FILE="${BUILD_WRAPPER_DL_LINUX}"
        BUILD_WRAPPER="${BUILD_WRAPPER_LINUX_CMD}"
    elif [ "$(st_is_os "Darwin")" == "true" ]; then
        printf "System is Darwin\\n"
        BUILD_WRAPPER_DL_URL="${BUILD_WRAPPER_DL_BASE}/${BUILD_WRAPPER_DL_MACOS}"
        BUILD_WRAPPER_DL_FILE="${BUILD_WRAPPER_DL_MACOS}"
        BUILD_WRAPPER="${BUILD_WRAPPER_MACOS_CMD}"
    else
        printf "Unrecognized OS\\n"
        exit 1
    fi

    if [ "$(st_try_command "${BUILD_WRAPPER}")" == "false" ]; then
        printf "Build wrapper not found in path, checking home directory cache\\n"

        extraction_folder=$(basename ${BUILD_WRAPPER_DL_FILE} .zip)

        if [ ! -d "${HOME}/.cache/sonar/${extraction_folder}" ]; then
            printf "Build wrapper not found in cache, downloading it\\n"

            tmpdir=$(mktemp -d)
            wget -q --directory-prefix="${tmpdir}" -c "${BUILD_WRAPPER_DL_URL}"

            mkdir -p "${HOME}/.cache/sonar"
            unzip "${tmpdir}/${BUILD_WRAPPER_DL_FILE}" -d "${HOME}/.cache/sonar"

            sync
            rm -r "${tmpdir}"

        else
            printf "Build wrapper found in home directory cache\\n"
        fi

        BUILD_WRAPPER="${HOME}/.cache/sonar/${extraction_folder}/${BUILD_WRAPPER}"
    fi

}

perform_scan() {
    printf "Performing sonar scan\\n"

    if [ ! -d "${build_dir}" ]; then
        mkdir -p "${build_dir}"
    fi

    cd "${build_dir}"

    if [[ ${cli_cmake} == "yes" ]]; then
        cmake "${cli_cmake_dir}" -DCMAKE_BUILD_TYPE=RELEASE
        verbose_opts="VERBOSE=1"
    fi

    "${BUILD_WRAPPER}" --out-dir bw-output make ${verbose_opts}

    if [[ ! "${cli_travis}" == "yes" ]]; then
        sonar-scanner -X
    fi
}

check_depends
get_build_wrapper
perform_scan

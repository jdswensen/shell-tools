#!/usr/bin/env bash
set -e

script_name=$(basename "$0")
script_dir="$( cd "$(dirname "$0")" ; pwd -P )"

# shellcheck source=/dev/null
. "${script_dir}/common"

usage() {
    printf "usage: %s [OPTS]\\n" "${script_name}"
    printf "OPTS:\\n"
    printf "    -c | --img-capacity             Total allowable image capacity\\n"
    printf "    -r | --ram-capacity             Total allowable RAM capacity\\n"
    printf "    -i | --input                    ELF input file\\n"
    printf "    -v | --verbose                  Verbose output\\n"
    exit 0
}

# See this explanation
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
# shellcheck disable=SC2086
if [ -z ${SIZE_TOOL+x} ]; then
    SIZE_TOOL="size"
    printf "SIZE_TOOL unset, using default: %s\\n" ${SIZE_TOOL};
fi

while [[ $# -gt 0 ]]; do
    case "${1}" in
        -i|--input) cli_input="${2}"; shift ;;
        -c|--img-capacity) cli_img_capacity="${2}"; shift ;;
        -r|--ram-capacity) cli_ram_capacity="${2}"; shift ;;
        -v|--verbose) cli_verbose="yes";;
        -h*|--help*|*) usage ;;
    esac
    shift
done

if [[ ${cli_verbose} == "yes" ]]; then
    set -x
fi

img_size_data=$("${SIZE_TOOL}" "${cli_input}")
text_size=$(echo "${img_size_data}" | grep -o -E '[0-9]+' | head -1)
data_size=$(echo "${img_size_data}" | grep -o -E '[0-9]+' | head -2 | tail -n 1)
bss_size=$(echo "${img_size_data}" | grep -o -E '[0-9]+' | head -3 | tail -n 1)

img_size=$(( text_size + data_size ))
if [ ! -z "${cli_img_capacity+x}" ]; then
    img_percent=$(( img_size * 100 / cli_img_capacity ))
else
    img_percent=100
fi

ram_size=$(( data_size + bss_size ))

if [ ! -z "${cli_ram_capacity+x}" ]; then
    ram_percent=$(( ram_size * 100 / cli_ram_capacity ))
else
    ram_percent=100
fi

printf "%s size:\\n" "${cli_input}"
printf "Image       %s bytes (%s%%)\\n" "${img_size}" "${img_percent}";
printf "RAM         %s bytes (%s%%)\\n" "${ram_size}" "${ram_percent}";
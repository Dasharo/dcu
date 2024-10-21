# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
MAC="${args[--set]}"
GBE_FLASHREGION_FILENAME="flashregion_3_gbe.bin"
GBE_FLASHREGION_PATH=$GBE_FLASHREGION_FILENAME
set_mac() {
  local _mac="$1"
  if "${NVMTOOL}" "$GBE_FLASHREGION_PATH" copy 0; then
    echo "Copying region 0 to region 1"
  else
    echo "Failed to copy region 0 to region 1"
    if "${NVMTOOL}" "$GBE_FLASHREGION_PATH" copy 1; then
      echo "Copying region 1 to region 0"
    else
      echo "Failed to copy region 1 to region 0"
      echo "Both regions are invalid, aborting"
      cleanup
      return 23
    fi
  fi

  "${NVMTOOL}" "$GBE_FLASHREGION_PATH" setmac "${_mac}" 1> /dev/null || { cleanup; return 22; }
  "${IFDTOOL}" -i gbe:"$GBE_FLASHREGION_PATH" "${DASHARO_ROM}" 1> /dev/null || { cleanup; return 21; }
  echo "Moving ${DASHARO_ROM}.new to ${DASHARO_ROM}"
  mv "${DASHARO_ROM}.new" "${DASHARO_ROM}" -f
  echo "Success"
}

get_mac() {
  # dump sections
  dump=$("${NVMTOOL}" "$GBE_FLASHREGION_PATH" "dump" 2>&1 || true)
  bad=$(printf "%s" "$dump" | grep "BAD checksum" 2>&1 || true)
  dump=$(echo "$dump" | sed "/BAD checksum in part 0/d" | sed "/BAD checksum in part 1/d")
  echo "$bad"
  echo "$dump"
  echo "Success"
}

init() {
  if [[ ! -f "${DASHARO_ROM}" ]]; then
    echo "Error, file does not exist: ${DASHARO_ROM}"
    cleanup
    return 1
  fi
  "${IFDTOOL}" -x "${DASHARO_ROM}" &> /dev/null
  if [[ ! -f "$GBE_FLASHREGION_PATH" ]]; then
    echo "Managing the MAC address in this binary is currently not supported"
    cleanup
    return 21
  fi
}

cleanup() {
  rm -f flashregion*
}
DASHARO_ROM=$(realpath -- "$DASHARO_ROM")
GBE_FLASHREGION_PATH=$(realpath -- "$GBE_FLASHREGION_PATH")
echo "Using ${DASHARO_ROM}"

init

if [ -n "${MAC}" ]; then
  set_mac "${MAC}"
else
  get_mac
fi

cleanup

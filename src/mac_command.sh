# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
MAC="${args[--set]}"
GBE_FLASHREGION_FILENAME="flashregion_3_gbe.bin"


set_mac() {
  local _mac="$1"
  if "${NVMTOOL}" "$GBE_FLASHREGION_FILENAME" copy 0; then
    echo "Copying region 0 to region 1"
  else
    echo "Failed to copy region 0 to region 1"
    if "${NVMTOOL}" "$GBE_FLASHREGION_FILENAME" copy 1; then
      echo "Copying region 1 to region 0"
    else
      echo "Failed to copy region 1 to region 0"
      echo "Both regions are invalid, aborting"
      return 23
    fi
  fi

  "${NVMTOOL}" "$GBE_FLASHREGION_FILENAME" setmac "${_mac}" || { echo "Failed to write MAC" ; return 22; }
  "${IFDTOOL}" -i gbe:"$GBE_FLASHREGION_FILENAME" "${DASHARO_ROM}" || { echo "Failed to insert gbe to the binary" ; return 21; }
  echo "Moving ${DASHARO_ROM}.new to ${DASHARO_ROM}"
  mv "${DASHARO_ROM}.new" "${DASHARO_ROM}" -f
  echo "Success"
}

get_mac() {
  # dump sections
  "${NVMTOOL}" "$GBE_FLASHREGION_FILENAME" dump
  echo "Success"
}

init() {
  "${IFDTOOL}" -x "${DASHARO_ROM}" > /dev/null 2>&1 || { echo "Failed to extract sections"; }
  if [[ ! -f "$GBE_FLASHREGION_FILENAME" ]]; then
    echo "Managing the MAC address in this binary is currently not supported"
    return 21
  fi
}

cleanup() {
  rm -f flashregion*
}

echo "Using ${DASHARO_ROM}"

init

if [ -n "${MAC}" ]; then
  set_mac "${MAC}"
else
  get_mac
fi

cleanup

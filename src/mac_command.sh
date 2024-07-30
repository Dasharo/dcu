# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
MAC="${args[--set]}"



set_mac() {
  local _mac="$1"

  "${IFDTOOL}" -x "${DASHARO_ROM}" > /dev/null 2>&1 || { echo "Failed to extract sections" ; return 1; }

  if "${NVMTOOL}" "flashregion_3_gbe.bin" copy 0; then
    echo "Copying region 0 to region 1"
  else
    echo "Failed to copy region 0 to region 1"
    if "${NVMTOOL}" "flashregion_3_gbe.bin" copy 1; then
      echo "Copying region 1 to region 0"
    else
      echo "Failed to copy region 1 to region 0"
      echo "Both regions are invalid, aborting"
      return 1
    fi
  fi

  "${NVMTOOL}" "flashregion_3_gbe.bin" setmac "${_mac}" || { echo "Failed to write MAC" ; return 1; }
  "${IFDTOOL}" -i gbe:flashregion_3_gbe.bin "${DASHARO_ROM}" || { echo "Failed to insert gbe to the binary" ; return 1; }
  echo "Moving ${DASHARO_ROM}.new to ${DASHARO_ROM}"
  mv "${DASHARO_ROM}.new" "${DASHARO_ROM}"
  echo "Success"
}

get_mac() {
  # dump sections
  "${IFDTOOL}" -x "${DASHARO_ROM}" > /dev/null 2>&1 || { echo "Failed to extract sections" ; return 1; }
  "${NVMTOOL}" "flashregion_3_gbe.bin" dump
  echo "Success"
}

cleanup() {
  rm -f flashregion*
}

echo "Will modify ${DASHARO_ROM}"

if [ -n "${MAC}" ]; then
  set_mac "${MAC}"
else
  get_mac
fi

cleanup

# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
SYSTEM_UUID="${args[--uuid]}"
SERIAL_NUMBER="${args[--serial-number]}"

set_uuid() {
  local _uuid="$1"

  if ! echo "${CB_CONFIG}" | grep -q "CONFIG_DRIVERS_GENERIC_CBFS_UUID=y"; then
    echo "Configurable UUID not supported by the coreboot image"
    exit 7
  fi

  if uuidparse "${SYSTEM_UUID}" | grep -q "invalid"; then
    echo "Invalid UUID format"
    exit 8
  fi

  echo "Setting System UUID to ${_uuid}"
  echo -n "${_uuid}" > /tmp/system_uuid
  # We do not care if this one fails. It can fail if serial_number is not
  # already, there, which is fine.
  "${CBFSTOOL}" "${DASHARO_ROM}" remove -n system_uuid -r COREBOOT > /dev/null 2> /dev/null || true
  CBFSTOOL_ERR="$(${CBFSTOOL} ${DASHARO_ROM} add -f /tmp/system_uuid -n system_uuid -t raw -r COREBOOT 2>&1)"
  rm /tmp/system_uuid

  if echo "${CBFSTOOL_ERR}" | grep -q "The image will be left unmodified"; then
    echo "An error occurred when adding setting the UUID"
    echo "cbfstool output:"
    echo "${CBFSTOOL_ERR}"
    exit 9
  fi
  echo "Success"
}

set_serial_number() {
  local _serial="$1"

  if ! echo "${CB_CONFIG}" | grep -q "CONFIG_DRIVERS_GENERIC_CBFS_SERIAL=y"; then
    echo "Configurable Serial Number not supported by the coreboot image"
    exit 10
  fi

  echo "Setting Serial Number to ${_serial}"
  echo -n "$_serial" > /tmp/serial_number
  # We do not care if this one fails. It can fail if serial_number is not
  # already, there, which is fine.
  "${CBFSTOOL}" "${DASHARO_ROM}" remove -n serial_number -r COREBOOT > /dev/null 2> /dev/null || true
  CBFSTOOL_ERR="$(${CBFSTOOL} ${DASHARO_ROM} add -f /tmp/serial_number -n serial_number -t raw -r COREBOOT 2>&1)"
  rm /tmp/serial_number

  if echo "${CBFSTOOL_ERR}" | grep -q "The image will be left unmodified"; then
    echo "An error occurred when adding setting the Serial Number"
    echo "cbfstool output:"
    echo "${CBFSTOOL_ERR}"
    exit 11
  fi
  echo "Success"
}

if ! "${CBFSTOOL}" "${DASHARO_ROM}" extract -n config -r COREBOOT -f /tmp/cb_config > /dev/null 2> /dev/null; then
  echo "Failed to extract coreboot configuration from the image"
  exit 6
fi

CB_CONFIG="$(cat /tmp/cb_config)"
rm /tmp/cb_config

echo "Will modify ${DASHARO_ROM}"
echo ""

if [ -n "${SYSTEM_UUID}" ]; then
  set_uuid "${SYSTEM_UUID}"
fi

if [ -n "${SERIAL_NUMBER}" ]; then
  set_serial_number "${SERIAL_NUMBER}"
fi

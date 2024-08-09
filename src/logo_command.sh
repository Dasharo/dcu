# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
LOGO_FILE="${args[--logo]}"

if [ ! -f "${LOGO_FILE}" ]; then
  echo "Logo file not found or invalid path: ${LOGO_FILE}"
  exit 12
fi

if ! file "${LOGO_FILE}" | grep -qE 'PNG image|JPEG image|Scalable Vector Graphics image|PC bitmap'; then
  echo "Invalid or unsupported logo file format"
  exit 13
fi

if ! "${CBFSTOOL}" "${DASHARO_ROM}" layout -w | grep -q "BOOTSPLASH"; then
  echo "BOOTSPLASH region not found"
  echo "Customizable logo not supported by the ${DASHARO_ROM} image"
  exit 14
fi

echo "Setting ${LOGO_FILE} as custom logo"
convert -background None ${LOGO_FILE} BMP3:/tmp/logo.bmp
# We do not care if this one fails. It can fail if serial_number is not
# already, there, which is fine.
"${CBFSTOOL}" "${DASHARO_ROM}" remove -n logo.bmp -r BOOTSPLASH > /dev/null 2> /dev/null || true
CBFSTOOL_ERR="$(${CBFSTOOL} ${DASHARO_ROM} add -f /tmp/logo.bmp -r BOOTSPLASH -n logo.bmp -t raw -c lzma 2>&1)"
rm /tmp/logo.bmp

if echo "${CBFSTOOL_ERR}" | grep -q "too big"; then
  echo "Logo file too big to fit in the coreboot image"
  exit 15
fi

if echo "$CBFSTOOL_ERR" | grep -q "The image will be left unmodified"; then
  echo "An error occurred when adding the logo to coreboot image"
  exit 16
fi

echo "Success"

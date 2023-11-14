#!/usr/bin/env bash

dl_test_file() {
  local _file="$1"
  local _url="$2"

  mkdir -p ./test/data

  if [ ! -f "./test/data/${_file}" ]; then
    wget -O "./test/data/${_file}" "${_url}"
  fi
}

# Supported commands:
# - logo
# - smbios (uuid, serial)
dl_test_file protectli_vault_cml_v1.2.0-rc1_vp46xx.rom https://cloud.3mdeb.com/index.php/s/KiFEzcLdtA2sA22/download

# Supported commands:
# - logo
dl_test_file novacustom_nv4x_adl_v1.6.0.rom  https://3mdeb.com/open-source-firmware/Dasharo/novacustom_nv4x_adl/v1.6.0/novacustom_nv4x_adl_v1.6.0.rom

# Supported commands:
# - NONE
dl_test_file protectli_vault_kbl_v1.0.14.rom https://3mdeb.com/open-source-firmware/Dasharo/protectli_vault_kbl/v1.0.14/protectli_vault_kbl_v1.0.14.rom

# Bootsplash
dl_test_file bootsplash.bmp https://raw.githubusercontent.com/Dasharo/dasharo-blobs/main/dasharo/bootsplash.bmp

# PDF (unsupported bootsplash format)
dl_test_file dummy.pdf https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf

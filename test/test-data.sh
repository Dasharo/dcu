#!/usr/bin/env bash

export DATA_DL_DIR="./data/dl"
export DATA_WORK_DIR="./data/work"

dl_test_file() {
  local _file="$1"
  local _url="$2"

  mkdir -p ./data

  if [ ! -f "${DATA_DL_DIR}/${_file}" ]; then
    wget -O "${DATA_DL_DIR}/${_file}" "${_url}"
  fi
}

download_test_data() {
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

  dl_test_file novacustom_v540tu_mtl_v0.9.0.rom http://dl.3mdeb.com/open-source-firmware/Dasharo/novacustom_v54x_mtl/v0.9.0/novacustom_v54x_mtl_v0.9.0.rom
  dl_test_file gbe.bin https://raw.githubusercontent.com/Dasharo/dasharo-blobs/mtl-h/novacustom/v5x0tu/gbe.bin
  ifdtool -i gbe:${DATA_DL_DIR}/gbe.bin ${DATA_DL_DIR}/novacustom_v540tu_mtl_v0.9.0.rom -O ${DATA_DL_DIR}/novacustom_v540tu_mtl_v0.9.0_gbe.rom &> /dev/null
}

refresh_test_data() {
  mkdir -p "${DATA_WORK_DIR}"
  cp ${DATA_DL_DIR}/* ${DATA_WORK_DIR}
}

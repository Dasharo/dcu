# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

CBFSTOOL="${CBFSTOOL:-$(which cbfstool)}"

if ! which cbfstool > /dev/null 2> /dev/null; then
  echo "cbfstool not found."
  echo "You can build one from source code: https://github.com/coreboot/coreboot/tree/main/util/cbfstool"
  echo "Or download pre-built version: https://dl.3mdeb.com/open-source-firmware/utilities/cbfstool"
  exit 5
fi

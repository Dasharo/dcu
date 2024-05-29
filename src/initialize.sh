# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

CBFSTOOL="cbfstool"
SMMSTORETOOL="smmstoretool"

error_exit() {
  _error_msg="$1"
  _exit_code="$2"
  if [ -n "$_error_msg" ]; then
    # Avoid printing empty line if no message was passed
    echo "$_error_msg"
  fi
  exit ${_exit_code}
}

error_check() {
  _error_code=$?
  _error_msg="$1"
  _exit_code="$2"
  [ $_error_code -ne 0 ] && error_exit "$_error_msg (error code: $_error_code)" ${_exit_code}
}

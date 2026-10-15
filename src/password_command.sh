# SPDX-FileCopyrightText: 2026 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
SET="${args[--set]}"
CHECK="${args[--check]}"
CLEAR="${args[--clear]}"
VALUE="${args[--value]}"

# gUserAuthenticationGuid (ee24a7f7-606b-4724-b3c9-f5ae4a3b8165) from
# DasharoModulePkg.dec, in the format smmstoretool accepts
PASSWORD_GUID="ee24a7f7-606b-4724-b3c9f5ae4a3b8165"
PASSWORD_VAR="Password"
# Variable layout: PasswordHash[32] followed by PasswordSalt[32]
PASSWORD_VAR_SIZE=64
# Limits enforced by UserAuthenticationDxe
PASSWORD_MIN_LEN=8
PASSWORD_MAX_LEN=64
PBKDF2_ITERATIONS=1000

if [ $(( ${SET:-0} + ${CHECK:-0} + ${CLEAR:-0} )) -gt 1 ]; then
  error_exit "Only one of --set, --check and --clear can be used at a time" 1
fi

if [ -n "${VALUE}" ] && [ -z "${SET}" ] && [ -z "${CHECK}" ]; then
  error_exit "--value can only be used with --set or --check" 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

to_hex()
{
  od -An -v -tx1 | tr -d ' \n'
}

# Prints the 32-byte PBKDF2 key for password $1 and the salt in file $2.
# The firmware hashes the ASCII password including its NUL terminator.
password_hash()
{
  openssl kdf -binary -keylen 32 -kdfopt digest:SHA256 \
    -kdfopt "hexpass:$(printf '%s' "$1" | to_hex)00" \
    -kdfopt "hexsalt:$(to_hex < "$2")" \
    -kdfopt "iter:${PBKDF2_ITERATIONS}" PBKDF2
}

validate_password()
{
  local _len=${#1}

  if [ ${_len} -lt ${PASSWORD_MIN_LEN} ] || [ ${_len} -gt ${PASSWORD_MAX_LEN} ]; then
    error_exit "Password must be ${PASSWORD_MIN_LEN} to ${PASSWORD_MAX_LEN} characters long" 1
  fi
  # Only characters that can be typed at the firmware prompt (US keyboard
  # layout) and stored as ASCII by the firmware
  # (the trailing "." keeps a newline from being stripped by $())
  if [ "$(printf '%s' "$1" | LC_ALL=C tr -d ' -~'; echo .)" != "." ]; then
    error_exit "Password may only contain printable ASCII characters" 1
  fi
}

# Reads a password into variable $1, from --value or by prompting with $2
read_password()
{
  if [ -n "${VALUE}" ]; then
    printf -v "$1" '%s' "${VALUE}"
    return
  fi
  if [ ! -t 0 ]; then
    error_exit "No terminal to prompt for the password, use --value instead" 1
  fi
  IFS= read -rs -p "$2" "$1"
  echo >&2
}

# Saves the Password variable to file $1. Returns 1 if it does not exist.
get_password_var()
{
  ${SMMSTORETOOL} "${DASHARO_ROM}" get -g ${PASSWORD_GUID} -n ${PASSWORD_VAR} \
    -t raw > "$1" 2>/dev/null
}

password_var_valid()
{
  [ "$(wc -c < "$1")" -eq ${PASSWORD_VAR_SIZE} ]
}

password_status()
{
  if ! get_password_var "${TMP_DIR}/password.bin"; then
    echo "Setup password is not set in ${DASHARO_ROM}."
  elif ! password_var_valid "${TMP_DIR}/password.bin"; then
    echo "Setup password variable in ${DASHARO_ROM} is malformed" \
         "($(wc -c < "${TMP_DIR}/password.bin") bytes instead of ${PASSWORD_VAR_SIZE})."
  else
    echo "Setup password is set in ${DASHARO_ROM}."
  fi
}

set_password()
{
  local _pw _pw2

  read_password _pw "New setup password: "
  validate_password "${_pw}"
  if [ -z "${VALUE}" ]; then
    read_password _pw2 "Confirm new setup password: "
    [ "${_pw}" = "${_pw2}" ] || error_exit "Passwords do not match" 1
  fi

  openssl rand -out "${TMP_DIR}/salt.bin" 32 \
    || error_exit "Failed to generate the password salt" 1
  password_hash "${_pw}" "${TMP_DIR}/salt.bin" > "${TMP_DIR}/password.bin" \
    || error_exit "Failed to hash the password" 1
  cat "${TMP_DIR}/salt.bin" >> "${TMP_DIR}/password.bin"

  # "file" is the input counterpart of the "raw" output type
  ${SMMSTORETOOL} "${DASHARO_ROM}" set -g ${PASSWORD_GUID} -n ${PASSWORD_VAR} \
    -t file -v "${TMP_DIR}/password.bin" \
    || error_exit "Failed to write the password to the variable store (smmstoretool supporting the \"file\" type is required)" 1
  echo "Successfully set the setup password in ${DASHARO_ROM}."
}

check_password()
{
  local _pw

  get_password_var "${TMP_DIR}/password.bin" \
    || error_exit "Setup password is not set in ${DASHARO_ROM}." 25
  password_var_valid "${TMP_DIR}/password.bin" \
    || error_exit "Setup password variable in ${DASHARO_ROM} is malformed." 1

  read_password _pw "Setup password: "
  tail -c 32 "${TMP_DIR}/password.bin" > "${TMP_DIR}/salt.bin"
  head -c 32 "${TMP_DIR}/password.bin" > "${TMP_DIR}/stored_hash.bin"
  password_hash "${_pw}" "${TMP_DIR}/salt.bin" > "${TMP_DIR}/hash.bin" \
    || error_exit "Failed to hash the password" 1

  if cmp -s "${TMP_DIR}/hash.bin" "${TMP_DIR}/stored_hash.bin"; then
    echo "Password matches."
  else
    error_exit "Password does not match." 24
  fi
}

clear_password()
{
  if ! get_password_var "${TMP_DIR}/password.bin"; then
    echo "Setup password is not set in ${DASHARO_ROM}."
    return
  fi
  ${SMMSTORETOOL} "${DASHARO_ROM}" remove -g ${PASSWORD_GUID} -n ${PASSWORD_VAR} \
    || error_exit "Failed to remove the password from the variable store" 1
  echo "Successfully cleared the setup password in ${DASHARO_ROM}."
}

if [ -n "${SET}" ]; then
  set_password
elif [ -n "${CHECK}" ]; then
  check_password
elif [ -n "${CLEAR}" ]; then
  clear_password
else
  password_status
fi

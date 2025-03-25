# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
SMMSTORETOOL="smmstoretool"
GET="${args[--get]}"
VALUE="${args[--value]}"
SET="${args[--set]}"
LIST="${args[--list]}"
LIST_SUPPORTED="${args[--list-supported]}"

supported_variables=$(echo "LockBios NetworkBoot UsbDriverStack SmmBwp"\
                    "Ps2Controller BootManagerEnabled PCIeResizeableBarsEnabled"\
                    "EnableCamera EnableWifiBt SerialRedirection SerialRedirection2"\
                    "MeMode FanCurveOption CpuThrottlingThreshold DGPUEnabled")

typeof()
{
  # TODO: determine type programmatically
  case $1 in
    LockBios \
    |NetworkBoot \
    |UsbDriverStack \
    |UsbMassStorage \
    |SmmBwp \
    |Ps2Controller \
    |BootManagerEnabled \
    |PCIeResizeableBarsEnabled \
    |EnableCamera \
    |EnableWifiBt \
    |SerialRedirection \
    |SerialRedirection2)
      echo "enum_bool"
      ;;
    MeMode)
      echo "enum_memode"
      ;;
    FanCurveOption)
      echo "enum_fancurve"
      ;;
    CpuThrottlingThreshold)
      echo "uint8"
      ;;
    DGPUEnabled)
      echo "enum_dgpuenabled"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

valueof()
{
  case `typeof $1` in
    enum_bool)
      _result="$(${SMMSTORETOOL} "${DASHARO_ROM}" get -g dasharo -n $1 -t bool)"
      error_check "Variable store was not initialized yet. You need to set some variable first via --set option." 17
      if [ "${_result}" = "false" ]; then
        echo "Disabled"
      elif [ "${_result}" = "true" ]; then
        echo "Enabled"
      else
        echo "Error!"
        exit 18
      fi
      ;;
    enum_memode)
      _result="$(${SMMSTORETOOL} "${DASHARO_ROM}" get -g dasharo -n $1 -t uint8)"
      error_check "Variable store was not initialized yet. You need to set some variable first via --set option." 17
      if [ "${_result}" = "0" ]; then
        echo "Enabled"
      elif [ "${_result}" = "1" ]; then
        echo "Disabled (Soft)"
      elif [ "${_result}" = "2" ]; then
        echo "Disabled (HAP)"
      else
        echo "Error!"
        exit 18
      fi
      ;;
    enum_fancurve)
      _result="$(${SMMSTORETOOL} "${DASHARO_ROM}" get -g dasharo -n $1 -t uint8)"
      error_check "Variable store was not initialized yet. You need to set some variable first via --set option." 17
      if [ "${_result}" = "0" ]; then
        echo "Silent"
      elif [ "${_result}" = "1" ]; then
        echo "Performance"
      else
        echo "Error!"
        exit 18
      fi
      ;;
    enum_dgpuenabled)
      _result="$(${SMMSTORETOOL} "${DASHARO_ROM}" get -g dasharo -n $1 -t uint8)"
      error_check "Variable store was not initialized yet. You need to set some variable first via --set option." 17
      case $_result in
        0) echo "iGPU Only";;
        1) echo "NVIDIA Optimus";;
        2) echo "dGPU Only";;
        *) echo "Error!"; exit 18;;
      esac
      ;;
    uint8)
      _result="$(${SMMSTORETOOL} "${DASHARO_ROM}" get -g dasharo -n $1 -t uint8)"
      error_check "Variable store was not initialized yet. You need to set some variable first via --set option." 17
      echo ${_result}
      ;;
    *)
      echo "Variable \"${1}\" is not supported by the DCU tool yet".
      exit 20
      ;;
  esac
}

acceptedvaluesfor()
{
  case `typeof $1` in
    enum_bool)
      echo "Disabled / Enabled"
      ;;
    enum_memode)
      echo "Enabled / Disabled (Soft) / Disabled (HAP)"
      ;;
    enum_fancurve)
      echo "Silent / Performance"
      ;;
    enum_dgpuenabled)
      echo "iGPU Only / NVIDIA Optimus / dGPU Only"
      ;;
    uint8)
      echo "0-255 (Actual supported values may vary)"
      ;;
    *)
      ;;
  esac
}

get_variable()
{
  echo "$(valueof ${GET})"
}

set_variable()
{
  if [ -z "${VALUE}" ]
  then
    echo "Value to set not provided, exiting" >&2
    exit 1
  fi

  if [[ $(typeof ${SET}) == enum_* ]]
  then
    # Enums: Find the index of the value in the list of accepted values, and
    # write it to the underlying variable as uint8.
    _accepted_values="$(acceptedvaluesfor ${SET})"
    _accepted_values_split=$(echo ${_accepted_values} | sed 's/\//\n/g')
    _accepted_values_count=$(echo "${_accepted_values_split}" | wc -l)

    if [ -z "${_accepted_values}" ]; then
      echo "Variable \"${SET}\" is not supported by the DCU tool yet".
      exit 20
    fi
    i=0
    export IFS="/"
    for a in ${_accepted_values} ; do
      a=$(echo $a | awk '{$1=$1};1')
      if [ "$a" = "${VALUE}" ]; then
        break
      fi
      i=$(($i + 1))
    done
    if [ ${i} -ge ${_accepted_values_count} ]; then
      echo "Value ${VALUE} is out of range (expected one of: ${_accepted_values})"
      exit 1
    fi
    set_value=${i}
    set_type="uint8"
  elif [[ $(typeof ${SET}) == "unknown" ]]; then
    echo "Variable \"${SET}\" is not supported by the DCU tool yet".
    exit 20
  else
    # All other types: Pass the type and value directly.
    set_value=${VALUE}
    set_type=$(typeof ${SET})
  fi

  ${SMMSTORETOOL} "${DASHARO_ROM}" set -g dasharo -n ${SET} -t ${set_type} -v ${set_value}
  echo "Successfully set variable ${SET} in the variable store."
}

list_variables()
{
  echo "Settings in ${DASHARO_ROM}:"
  variables=$(${SMMSTORETOOL} "${DASHARO_ROM}" list | grep "dasharo" | sed 's/.*://; s/(.*//')
  tabs 30
  echo -e "NAME\tVALUE\tACCEPTED VALUES"
  for var in $variables; do
    case `typeof $var` in
      enum_bool \
      |enum_memode \
      |enum_fancurve \
      |enum_dgpuenabled \
      |uint8)
        echo -e "$var\t$(valueof $var)\t$(acceptedvaluesfor $var)"
        ;;
      *)
        ;;
    esac
  done
}

list_supported_variables()
{
  echo "Settings that can be modified using this tool":
  tabs 30
  echo -e "NAME\tACCEPTED VALUES"
  for var in $supported_variables; do
    echo -e "$var\t$(acceptedvaluesfor $var)"
  done
}

if [ -n "${GET}" ]
then
  get_variable
elif [ -n "${LIST}" ]
then
  list_variables
elif [ -n "${SET}" ]
then
  set_variable
elif [ -n "${LIST_SUPPORTED}" ]
then
  list_supported_variables
fi

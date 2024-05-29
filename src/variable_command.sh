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
      echo "bool"
      ;;
    MeMode)
      echo "memode"
      ;;
    FanCurveOption)
      echo "fancurve"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

valueof()
{
  case `typeof $1` in
    bool)
      _result="$(${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t bool)"
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
    memode)
      _result="$(${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8)"
      error_check "Variable store was not initialized yet. You need to set some variable first via --set option." 17
      if [ "${_result}" = "0" ]; then
        echo "Enabled"
      elif [ "${_result}" = "1" ]; then
        echo "DisabledSoft"
      elif [ "${_result}" = "2" ]; then
        echo "DisabledHAP"
      else
        echo "Error!"
        exit 18
      fi
      ;;
    fancurve)
      _result="$(${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8)"
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
    *)
      echo "Variable \"${1}\" is not supported by the DCU tool yet".
      exit 20
      ;;
  esac
}

acceptedvaluesfor()
{
  case `typeof $1` in
    bool)
      echo "Disabled / Enabled"
      ;;
    memode)
      echo "Enabled / DisabledSoft / DisabledHAP"
      ;;
    fancurve)
      echo "Silent / Performance"
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

  _accepted_values="$(acceptedvaluesfor ${SET})"
  _accepted_values_split=$(echo ${_accepted_values} | sed "s/\///g")
  _accepted_values_count=$(echo ${_accepted_values_split} | wc -w)

  if [ -z "${_accepted_values}" ]; then
    echo "Variable \"${SET}\" is not supported by the DCU tool yet".
    exit 20
  fi
  i=0
  for a in ${_accepted_values_split} ; do
    if [ $a = ${VALUE} ]; then
      break
    fi
    i=$(($i + 1))
  done
  if [ ${i} -ge ${_accepted_values_count} ]; then
    echo "Value ${VALUE} is out of range (expected one of: ${_accepted_values})"
    exit 1
  fi

  ${SMMSTORETOOL} ${DASHARO_ROM} set -g dasharo -n ${SET} -t uint8 -v ${i}
  echo "Successfully set variable ${SET} in the variable store."
}

list_variables()
{
  echo "Settings that can be modified using this tool:"
  variables=$(${SMMSTORETOOL} ${DASHARO_ROM} list | grep "dasharo" | sed 's/.*://; s/(.*//')
  tabs 30
  echo -e "NAME\tVALUE\tACCEPTED VALUES"
  for var in $variables; do
    case `typeof $var` in
      bool)
        echo -e "$var\t$(valueof $var)\t$(acceptedvaluesfor $var)"
        ;;
      memode)
        echo -e "$var\t$(valueof $var)\t$(acceptedvaluesfor $var)"
        ;;
      fancurve)
        echo -e "$var\t$(valueof $var)\t$(acceptedvaluesfor $var)"
        ;;
      *)
        ;;
    esac
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
fi

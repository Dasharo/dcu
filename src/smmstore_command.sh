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
  # TODO: determine type programatically
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
      if [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t bool` = "false" ]; then
        echo "Disabled"
      elif [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t bool` = "true" ]; then
        echo "Enabled"
      else
        echo "Error!"
        exit 1
      fi
      ;;
    memode)
      if [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8` = "0" ]; then
        echo "Enabled"
      elif [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8` = "1" ]; then
        echo "DisabledSoft"
      elif [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8` = "2" ]; then
        echo "DisabledHAP"
      else
        echo "Error!"
        exit 1
      fi
      ;;
    fancurve)
      if [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8` = "0" ]; then
        echo "Silent"
      elif [ `${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n $1 -t uint8` = "1" ]; then
        echo "Performance"
      else
        echo "Error!"
        exit 1
      fi
      ;;
  esac
}

acceptedvaluesfor()
{
  case `typeof $1` in
    bool)
      echo "Enabled / Disabled"
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
  echo $(valueof ${GET})
}

set_variable()
{
  if [ -z "${VALUE}" ]
  then
    echo "Value to set not provided, exiting" >&2
    exit 1
  fi
  i=0
  for a in $(acceptedvaluesfor ${SET} | sed "s/\///g"); do
    if [ $a = ${VALUE} ]; then
      break
    fi
    i=$(($i + 1))
  done
  if [ ${i} -ge $(echo acceptedvaluesfor ${SET} | sed "s/\///g" | wc -w) ]; then
    echo "Value ${VALUE} is out of range (expected one of: $(acceptedvaluesfor ${SET}))"
    exit 1
  fi

  ${SMMSTORETOOL} ${DASHARO_ROM} set -g dasharo -n ${SET} -t uint8 -v ${i}
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

# SPDX-FileCopyrightText: 2023 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# inspect_args

DASHARO_ROM="${args[dasharo_rom_file]}"
GET="${args[--get]}"
VALUE="${args[--value]}"
SET="${args[--set]}"

get_variable()
{
	${SMMSTORETOOL} ${DASHARO_ROM} get -g dasharo -n ${GET} -t bool
	if [ $? -neq 0 ]
	then
		echo "Error, correct passed arguments"
		exit 1
	fi
}

set_variable()
{
	if [ -z "${VALUE}" ]
	then
		echo "Value to set not provided, exiting" >&2
		exit 1
	fi
	${SMMSTORETOOL} ${DASHARO_ROM} set -g dasharo -n ${SET} -t bool -v ${VALUE}
	if [ $? -neq 0 ]
	then
		echo "Error, correct passed arguments" >&2
		exit 1
	fi
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

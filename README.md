# DCU - Dasharo Configuration Utility

## Introduction

The Dasharo Configuration Utility is a tool designed to configure Dasharo firmware
binary images. It includes task such as customizing the boot logo, and setting
unique UUIDs or Serial Numbers in SMBIOS tables.

DCU can be run in two modes - standalone, or as a container. The container setup
contains all of the prerequisites, so it should be easier to use.

## Prerequisites

### Dasharo Configuration Utility Container

* [Docker Engine installed](https://docs.docker.com/engine/install/)

### Standalone DCU

Following packages must be installed:

* `imagemagick` (for `convert` command)
* `util-linux` (for `uuidparse` command)
* [coreboot's cbfstool](https://github.com/coreboot/coreboot/tree/master/util/cbfstool)

The script will exit with an error if any of above are not present.

#### Compiling cbfstool

The cbfstool can be compiled from source if needed.

```bash
git clone https://review.coreboot.org/coreboot.git
cd coreboot
TOOLLDFLAGS=-static make -C util/cbfstool
strip --strip-unneeded util/cbfstool/cbfstool
TOOLLDFLAGS=-static sudo make -C util/cbfstool install
```

#### Compiling smmstoretool

The smmstoretool can be compiled from source if needed.

```bash
git clone https://review.coreboot.org/coreboot.git
cd coreboot
TOOLLDFLAGS=-static make -C util/smmstoretool
strip --strip-unneeded util/smmstoretool/smmstoretool
TOOLLDFLAGS=-static sudo make -C util/smmstoretool install
```

#### Compiling nvmtool

The nvmtool can be compiled from source if needed.

```bash
git clone https://review.coreboot.org/coreboot.git
cd coreboot
git fetch https://review.coreboot.org/coreboot refs/changes/29/67129/5
git checkout -b change-67129 FETCH_HEAD
cd util/nvmtool
make
```

Now you can install it by copying or linking the resulting `nvm`
executable into a directory existing in your $PATH, for example:
* `usr/local/bin`
* `usr/bin`.
* $HOME/.local/bin

#### Compiling ifdtool

The ifdtool can be compiled from source if needed.

```bash
git clone https://review.coreboot.org/coreboot.git
cd coreboot
make -C util/ifdtool
sudo make -C util/ifdtool install
```

## Usage

`dcu` can be used as a standalone script, and is also available in the
[Dasharo Tools Suite](https://docs.dasharo.com/dasharo-tools-suite/overview/).

To use `dcu` as a standalone script (or using a container), you should clone
the repository first:

```shell
git clone https://github.com/Dasharo/dcu.git
```

### Dasharo Configuration Container

Simply use `dcuc` instead od `dcu`, and follow the section below.

### Standalone

The script will save the UUID and Serial Number to the COREBOOT region and the
logo to BOOTSPLASH region.

NOTE: Not all Dasharo platform support such customizations.

NOTE: if you update the firmware by rewriting whole BIOS region, the data will
be lost. To avoid data loss during the COREBOOT region update, Dasharo
firmware will keep the copies of Serial Number and UUID in the UEFI variables
on normal boot, so that in the potential firmware update in the future, the
data will be kept (as long as UEFI variables are not erased).

Simply run the script with `-h` or `--help` flags to get documentation and examples
of the available commands.

Common actions:

* Change boot logo:

```bash
./dcu logo coreboot.rom -l bootsplash.bmp
```

* Get a list of settings in a binary

```bash
/dcu variable --list coreboot.rom
Settings in coreboot.rom:
NAME		VALUE			ACCEPTED VALUES
MeMode		Disabled (Soft)		Enabled / Disabled (Soft) / Disabled (HAP)
```

* Change a setting

```bash
./dcu variable coreboot.rom --set "MeMode" --value "Disabled (Soft)"
```

* Get a list of settings supported by this tool:

```bash
./dcu variable --list-supported coreboot.rom
Settings that can be modified using this tool:
NAME				ACCEPTED VALUES
LockBios			Disabled / Enabled
NetworkBoot			Disabled / Enabled
UsbDriverStack			Disabled / Enabled
SmmBwp				Disabled / Enabled
Ps2Controller			Disabled / Enabled
BootManagerEnabled		Disabled / Enabled
PCIeResizeableBarsEnabled	Disabled / Enabled
EnableCamera			Disabled / Enabled
EnableWifiBt			Disabled / Enabled
SerialRedirection		Disabled / Enabled
SerialRedirection2		Disabled / Enabled
MeMode				Enabled / Disabled (Soft) / Disabled (HAP)
FanCurveOption			Silent / Performance
CpuThrottlingThreshold		0-255 (Actual supported values may vary)
```

> Note: Actual implemented values may vary between devices. For example, CPU
> throttling temperature is adjustable from TjMax to TjMax-63. To see what
> values are implemented in a given build, check the UEFI setup menu.

## Error codes

* 0 - no error
* 1 - unknown argument/option
* 2 - `uuidparse` not found
* 3 - `convert` not found
* 4 - coreboot image not found or invalid path
* 5 - `cbfstool` not found
* 6 - failed to extract coreboot configuration file from coreboot image
* 7 - configurable UUID not supported by given coreboot image
* 8 - invalid UUID format
* 9 - failed to set the UUID (more detailed error information in the script
      output)
* 10 - configurable Serial Number not supported by given coreboot image
* 11 - failed to set the Serial Number (more detailed error information in the
       script output)
* 12 - logo file not found or invalid path
* 13 - unsupported logo file format
* 14 - customizable logo not supported by given coreboot image
* 15 - logo file too big to fit in given coreboot image
* 16 - failed to set the logo (more detailed error information in the script
       output)
* 17 - tried to read a variable that isn't set yet, most likely because the
       firmware image has not been booted yet
* 18 - failed to read value of a configuration variable
* 20 - configuration variable not yet supported in DCU
* 21 - provided image is not supported by `mac` subcommand
* 22 - invalid MAC address format
* 23 - MAC addresses in the image are invalid

## Development

Please note that after every code modification in `src` you have to run `bashly
generate`. Typical developer workflow would looks as follows:

1. Set alias for bashly:

  ```bash
  alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'
  ```

1. Perform code modification in `src` directory.
1. Apply changes by `bashly generate`
1. Test your changes.
1. If your changes work as expected create pull request.

## Testing

We are using
[approvals.bash](https://github.com/dannyben/approvals.bash#readme) here.

How to run test and/or refresh the expected outputs:

1. Edit the `./test/approve` to create desired test cases.

1. Run tests (or refresh expected outputs)

  ```bash
  ./test/approve
  ```

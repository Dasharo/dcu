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
1. Get the test data:

  ```bash
  ./test/get-test-data.sh
  ```

1. Run tests (or refresh expected outputs)

  ```bash
  ./test/approve
  ```

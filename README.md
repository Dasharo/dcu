# dcu - Dasharo Configuration Utility

## Introduction

The Dasharo Configuration Utility is a script designed to facilitate tasks such
as customizing the boot logo and setting unique UUIDs or Serial Numbers for
SMBIOS. This readme provides only the most basic information. For details
please refer to [our guide](https://docs.dasharo.com/guides/image-customization/)
.

## Prerequisites

Following packages must be installed:

* `imagemagick` (for `convert` command)
* `util-linux` (for `uuidparse` command)
* [coreboot's
cbfstool](https://github.com/coreboot/coreboot/tree/master/util/cbfstool)

## Usage

```txt
Usage: dcu OPTIONS coreboot.rom

  coreboot.rom  - Dasharo coreboot file to modify

  OPTIONS:
    -u | --uuid <UUID>              - UUID in RFC4122 format to be set in SMBIOS type 1 structure
    -s | --serial-number <SERIAL>   - Serial number to be set in SMBIOS type 1 and type 2 structure
    -l | --logo <LOGO>              - Custom logo in BMP/PNG/JPG/SVG format to be displayed on boot

  Examples:
    ./dcu -u 96bcfa1a-42b4-6717-a44c-d8bbc18cbea4 -s D07229051 -l ~/logo.svg coreboot.rom

    ./dcu -u `dmidecode -s system-uuid` -s `dmidecode -s baseboard-serial-number` coreboot.rom
      Above command will obtain the current SMBIOS UUID and Serial Number
      from the system and patch the coreboot binary.
```

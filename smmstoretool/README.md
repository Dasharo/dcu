# smmstoretool

Offline SMMSTORE variable modification tool.

## Operation

If SMMSTORE presence isn't detected and an update operation is requested, the
store spanning the whole file is created automatically.  Size of the store file
must be a multiple of 64 KiB, the storage itself will be 64 KiB in size.  The
store won't span the whole file because that's how EDK2 creates it as well and
it will reformat the store if doesn't match (could be EDK2's configuration
issue).

Unlike online editing which mostly appends new variable entries each storage
update with this tool drops all deleted or incomplete entries.

## Help

Start with:

```
$ smmstoretool -h
Usage: smmstoretool smm-store-file sub-command
       smmstoretool -h|--help

Sub-commands:
 * get    - display current value of a variable
 * guids  - show GUID to alias mapping
 * help   - provide built-in help
 * list   - list variables present in the store
 * remove - remove a variable from the store
 * set    - add or updates a variable in the store
```

Then run `smmstoretool rom help sub-command-name` to get more details.

## Variable listing example

```
$ smmstoretool SMMSTORE list
dasharo                            :NetworkBoot (1 byte)
c076ec0c-7028-4399-a07271ee5c448b9f:CustomMode (1 byte)
d9bee56e-75dc-49d9-b4d7b534210f637a:certdb (4 bytes)
9073e4e0-60ec-4b6e-99034c223c260f3c:VendorKeysNv (1 byte)
6339d487-26ba-424b-9a5d687e25d740bc:TCG2_DEVICE_DETECTION (1 byte)
6339d487-26ba-424b-9a5d687e25d740bc:TCG2_CONFIGURATION (1 byte)
6339d487-26ba-424b-9a5d687e25d740bc:TCG2_VERSION (16 bytes)
global                             :Boot0000 (66 bytes)
global                             :Timeout (2 bytes)
global                             :PlatformLang (3 bytes)
global                             :Lang (4 bytes)
global                             :Key0000 (14 bytes)
global                             :Boot0001 (102 bytes)
global                             :Key0001 (14 bytes)
04b37fe8-f6ae-480b-bdd537d98c5e89aa:VarErrorFlag (1 byte)
dasharo                            :Type1UUID (16 bytes)
dasharo                            :Type2SN (10 bytes)
global                             :Boot0002 (90 bytes)
global                             :BootOrder (8 bytes)
global                             :Boot0003 (76 bytes)
c095791a-3001-47b2-80c9eac7319f2fa4:FirmwarePerformance (16 bytes)
dasharo                            :LockBios (1 byte)
dasharo                            :SmmBwp (1 byte)
dasharo                            :MeMode (1 byte)
dasharo                            :OptionRomPolicy (1 byte)
dasharo                            :Ps2Controller (1 byte)
dasharo                            :WatchdogConfig (3 bytes)
dasharo                            :WatchdogAvailable (1 byte)
dasharo                            :BootManagerEnabled (1 byte)
dasharo                            :FanCurveOption (1 byte)
dasharo                            :IommuConfig (2 bytes)
dasharo                            :SleepType (1 byte)
dasharo                            :PowerFailureState (1 byte)
dasharo                            :PCIeResizeableBarsEnabled (1 byte)
dasharo                            :EnableCamera (1 byte)
dasharo                            :EnableWifiBt (1 byte)
dasharo                            :BatteryConfig (2 bytes)
dasharo                            :MemoryProfile (1 byte)
dasharo                            :SerialRedirection (1 byte)
dasharo                            :UsbDriverStack (1 byte)
dasharo                            :UsbMassStorage (1 byte)
eb704011-1402-11d3-8e7700a0c969723b:MTC (4 bytes)
global                             :ConOut (30 bytes)
global                             :ConIn (15 bytes)
global                             :ErrOut (30 bytes)
```

## Variable reading example

```
$ smmstoretool SMMSTORE get -g dasharo -n UsbDriverStack -t bool
false
```

## Variable writing example

```
$ smmstoretool SMMSTORE set -g dasharo -n UsbDriverStack -t bool -v true
```

## Varialbe deletion example

```
$ smmstoretool SMMSTORE remove -g dasharo -n NetworkBoot
```

## Usage example

If one edits a newly generated Dasharo `coreboot.rom`:

```bash
cbfstool coreboot.rom read -r SMMSTORE -f SMMSTORE
smmstoretool SMMSTORE set -g dasharo -n NetworkBoot -t bool -v true
cbfstool coreboot.rom write -r SMMSTORE -f SMMSTORE
```

On the first boot, "Network Boot" setting should already be enabled.

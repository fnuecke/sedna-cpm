# sedna-cpm

CP/M 2.2 for [Sedna](https://github.com/fnuecke/sedna)'s Z80 board.

CCP and BDOS come from [brouhaha/cpm22](https://github.com/brouhaha/cpm22) (see submodule).

## Building

Requires Docker and a JDK 21.

```bash
git submodule update --init
./gradlew build
```

## Memory layout

| region | range           | size    |
|--------|-----------------|---------|
| TPA    | `0100h`-`E1FFh` | 57600 B |
| CCP    | `E200h`-`E9FFh` | 2 KiB   |
| BDOS   | `EA00h`-`F7FFh` | 3.5 KiB |
| BIOS   | `F800h`-`FFFFh` | 2 KiB   |

The origins are passed to the assembler; BDOS derives the BIOS base itself as
`($ & 0ff00h)+100h`, which lands on `F800h` for these values.

## Device discovery in CBIOS

Port `E0h` must be Sedna's device enumeration window. It's the only address the BIOS hardcodes. Rest of the devices can
sit wherever, they'll be identified using the enumeration device. Which is what allows dynamic configurations for e.g.
oc2. `DEVLIB.INC` on the floppy provides the means for guest programs to look for devices and talk to them. `DEVS.COM`
prints the current list.

## License

Source in this repository is MIT (see `LICENSE`). The boot ROM and floppy image embedding CP/M 2.2's CCP and BDOS are
covered by the CP/M grant in `external/cpm22/LICENSE.txt` and are not MIT.

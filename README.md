# sedna-cpm

CP/M 2.2 for [Sedna](https://github.com/fnuecke/sedna)'s Z80 board.

CCP and BDOS come from [brouhaha/cpm22](https://github.com/brouhaha/cpm22) (see submodule).

The assembler and linker are A.E. Hawley's ZMAC and ZML, committed under `vendor/hawley`.

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

## Floppy files

| file         | description                                                        |
|--------------|--------------------------------------------------------------------|
| `DEVS.COM`   | prints the devices the enumeration window reports                  |
| `DEVLIB.INC` | device discovery for your own programs, see above                  |
| `ZMAC.COM`   | Z80 macro assembler, standard Zilog mnemonics, `INCLUDE` supported |
| `ZML.COM`    | linker, turns the assembler's output into a program                |
| `ED.COM`     | Digital Research's line editor                                     |

Build a program with `ZMAC PROG` (`PROG.Z80` in, `PROG.REL` out) then `ZML PROG` (`PROG.COM` out).
`ZMAC` takes `/C` for a console listing and `/H` to emit Intel hex instead.

`ED` is built from Digital Research's own PL/M sources by
[ivop/cpm22-from-source](https://github.com/ivop/cpm22-from-source).

Guest source files have to be stored the way CP/M expects, with CRLF line endings and a `1Ah` after the last one.
Otherwise, files look like one long line to these tools. `.gitattributes` keeps `.inc` checked out as CRLF, and the
`Makefile` adds the terminator on the way onto the image.

## License

- CP/M 2.2's CCP and BDOS, in the boot ROM and the image: `external/cpm22/LICENSE.txt`.
- `ZMAC.COM` and `ZML.COM`: `vendor/hawley/README.md`.
- `ED.COM`: `external/cpm22-utils/LICENSE`.
- `DEVS.COM` and `DEVLIB.INC`: `LICENSE`.

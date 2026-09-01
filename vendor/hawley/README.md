# ZMAC and ZML

A Z80 macro assembler and its linker, by A.E. Hawley.

| file       | what it is                              | sha256                                                             |
|------------|-----------------------------------------|--------------------------------------------------------------------|
| `zmac.com` | ZMAC 1.7 (04/09/93), macro assembler    | `d01eb060c282aabeff01ec590f33f1b7b4455e6ebd23ae90039e5c7d9cc6ac6e` |
| `zml.com`  | ZML, relocatable linker                 | `36b84a8da3d2d9be7b14d5a27af2da9d1deb1a1b7ed54f7d9408287e66fb56b8` |

## Source

`http://www.cpm.z80.de/develop/zmac.zip`, sha256
`64c575df0dfd6819c81f0e8d85da23d8404c02e8a32d238c89be3c02fed229d2`.

The original archive contains compressed programs (`ZMAC.CZM`, `ZML.CZM`). They were
unpacked using `UNCR.COM` by running it on CP/M in Sedna:

```bash
sedna-cli cpm --disk work.img      # then, at the prompt: B:, UNCR *.CZM
cpmcp -f sedna work.img 0:zmac.com zmac.com/
```

## Licence

Distributed under grant from the author, quoted on the page above:

> From: Al Hawley
> Date: Sat, 25 May 2002 22:04:09 -0700
>
> Hal, as far as I am concerned, ZMAC and ZML can be distributed freely with no
> strings attached.

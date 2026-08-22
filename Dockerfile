FROM debian:bookworm-slim@sha256:abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241

# Alfred Arnold's Macro Assembler AS, which cpm22 needs.
ARG ASL_COMMIT=c7155b4fd3d33110f0eb098dede4295a8c008772

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates cpmtools=2.23-4 git make \
 && rm -rf /var/lib/apt/lists/*

RUN git init -q /tmp/asl \
 && git -C /tmp/asl remote add origin https://github.com/Macroassembler-AS/asl-releases.git \
 && git -C /tmp/asl fetch -q --depth 1 origin "${ASL_COMMIT}" \
 && git -C /tmp/asl checkout -q FETCH_HEAD \
 && printf '%s\n' \
      'OBJDIR =' \
      'CC = gcc' \
      'CFLAGS = -O2 -w' \
      'HOST_OBJEXTENSION = .o' \
      'LD = $(CC)' \
      'LDFLAGS =' \
      'HOST_EXEXTENSION =' \
      'TARG_OBJDIR = $(OBJDIR)' \
      'TARG_CC = $(CC)' \
      'TARG_CFLAGS = $(CFLAGS)' \
      'TARG_OBJEXTENSION = $(HOST_OBJEXTENSION)' \
      'TARG_LD = $(LD)' \
      'TARG_LDFLAGS = $(LDFLAGS)' \
      'TARG_EXEXTENSION = $(HOST_EXEXTENSION)' \
      'INSTROOT:=/usr/local' \
      > /tmp/asl/Makefile.def \
 && make -C /tmp/asl -j"$(nproc)" dft >/dev/null \
 && (cd /tmp/asl && INSTROOT=/usr/local ./install.sh bin include/asl "" lib/asl "") \
 && rm -rf /tmp/asl

ENV AS_MSGPATH=/usr/local/lib/asl \
    AS_INCPATH=/usr/local/include/asl

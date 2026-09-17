# Runs inside the container from Dockerfile; see build.gradle.kts. Everything lands in build/.

ASM      := src/main/asm
CPM22    := external/cpm22
BUILD    := build/cpm
DISKDEFS := src/main/diskdefs/diskdefs

HAWLEY   := vendor/hawley
UTILS    := external/cpm22-utils

CPMSIZE  := $(shell awk '/^[ \t]*tracks/{t=$$2} /^[ \t]*sectrk/{s=$$2} /^[ \t]*seclen/{l=$$2} END{print t*s*l}' $(DISKDEFS))
BOOTSIZE := $(shell awk '/^[ \t]*boottrk/{b=$$2} /^[ \t]*sectrk/{s=$$2} /^[ \t]*seclen/{l=$$2} END{print b*s*l}' $(DISKDEFS))
SECLEN   := $(shell awk '/^[ \t]*seclen/{print $$2}' $(DISKDEFS))

MEMMAP   := $(ASM)/memmap.inc
memhex    = $(shell awk '$$1=="$(1)"{v=$$3; gsub(/\r/,"",v); sub(/h$$/,"",v); print v}' $(MEMMAP))
memaddr   = $(shell printf '%d' 0x$(call memhex,$(1)))

CCP_ORG  := $(call memhex,CCP)h
BDOS_ORG := $(call memhex,BDOS)h
CCP_A    := $(call memaddr,CCP)
BDOS_A   := $(call memaddr,BDOS)
BIOS_A   := $(call memaddr,BIOS)
MEMTOP_A := $(call memaddr,MEMTOP)

.PHONY: all clean
all: $(BUILD)/bootrom.bin $(BUILD)/cpm.img $(BUILD)/geometry.properties

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/ccp.bin: $(CPM22)/ccp.asm $(ASM)/memmap.inc | $(BUILD)
	asl -D origin=$(CCP_ORG),noserial,noserialize -o $(BUILD)/ccp.p -L -OLIST $(BUILD)/ccp.lst $<
	p2bin -l '$$00' -r "$(CCP_A)-$$(( $(BDOS_A) - 1 ))" $(BUILD)/ccp.p

$(BUILD)/bdos.bin: $(CPM22)/bdos.asm $(ASM)/memmap.inc | $(BUILD)
	asl -D origin=$(BDOS_ORG) -o $(BUILD)/bdos.p -L -OLIST $(BUILD)/bdos.lst $<
	p2bin -l '$$00' -r "$(BDOS_A)-$$(( $(BIOS_A) - 1 ))" $(BUILD)/bdos.p

$(BUILD)/geometry.inc: $(DISKDEFS) Makefile | $(BUILD)
	awk '/^[ \t]*tracks/{printf "DSKTRK\tequ\t%s\n", $$2} \
	     /^[ \t]*sectrk/{printf "DSKSEC\tequ\t%s\n", $$2} \
	     /^[ \t]*seclen/{printf "DSKLEN\tequ\t%s\n", $$2} \
	     /^[ \t]*blocksize/{printf "DSKBLS\tequ\t%s\n", $$2} \
	     /^[ \t]*maxdir/{printf "DSKDIR\tequ\t%s\n", $$2} \
	     /^[ \t]*boottrk/{printf "DSKOFF\tequ\t%s\n", $$2}' $(DISKDEFS) > $@

$(BUILD)/geometry.properties: $(DISKDEFS) Makefile | $(BUILD)
	awk '/^[ \t]*tracks/{printf "tracks=%s\n", $$2} \
	     /^[ \t]*sectrk/{printf "sectorsPerTrack=%s\n", $$2} \
	     /^[ \t]*seclen/{printf "sectorSize=%s\n", $$2} \
	     /^[ \t]*blocksize/{printf "blockSize=%s\n", $$2} \
	     /^[ \t]*maxdir/{printf "directoryEntries=%s\n", $$2} \
	     /^[ \t]*boottrk/{printf "reservedTracks=%s\n", $$2}' $(DISKDEFS) > $@

$(BUILD)/cbios.bin: $(ASM)/cbios.asm $(ASM)/memmap.inc $(ASM)/bootdef.inc $(ASM)/wd1793.inc $(ASM)/devlib.inc $(BUILD)/geometry.inc | $(BUILD)
	asl -i $(ASM):$(BUILD) -o $(BUILD)/cbios.p -L -OLIST $(BUILD)/cbios.lst $<
	p2bin -l '$$00' -r "$(BIOS_A)-$$(( $(MEMTOP_A) - 1 ))" $(BUILD)/cbios.p

$(BUILD)/bootsec.bin: $(ASM)/bootsec.asm $(ASM)/memmap.inc $(ASM)/bootdef.inc $(BUILD)/geometry.inc | $(BUILD)
	asl -i $(ASM):$(BUILD) -o $(BUILD)/bootsec.p -L -OLIST $(BUILD)/bootsec.lst $<
	p2bin -l '$$00' -r "0-$$(( $(SECLEN) - 1 ))" $(BUILD)/bootsec.p

$(BUILD)/bootarea.bin: $(BUILD)/bootsec.bin $(BUILD)/ccp.bin $(BUILD)/bdos.bin $(BUILD)/cbios.bin
	cat $^ > $@
	@test "$$(stat -c %s $@)" -le "$(BOOTSIZE)" \
	  || { echo "boot area is larger than the reserved tracks"; exit 1; }

$(BUILD)/bootrom.bin: $(ASM)/bootrom.asm $(ASM)/bootdef.inc $(ASM)/wd1793.inc $(ASM)/devlib.inc | $(BUILD)
	asl -i $(ASM) -o $(BUILD)/bootrom.p -L -OLIST $(BUILD)/bootrom.lst $<
	p2bin -l '$$00' -r '$$0000-$$03FF' $(BUILD)/bootrom.p

$(BUILD)/devs.com: $(ASM)/devs.asm $(ASM)/devlib.inc | $(BUILD)
	asl -i $(ASM) -o $(BUILD)/devs.p -L -OLIST $(BUILD)/devs.lst $<
	p2bin -l '$$00' $(BUILD)/devs.p
	mv $(BUILD)/devs.bin $@

$(BUILD)/term.com: $(ASM)/term.asm $(ASM)/devlib.inc $(ASM)/serial.inc | $(BUILD)
	asl -i $(ASM) -o $(BUILD)/term.p -L -OLIST $(BUILD)/term.lst $<
	p2bin -l '$$00' $(BUILD)/term.p
	mv $(BUILD)/term.bin $@

$(BUILD)/ed.com: $(UTILS)/src/ed.plm | $(BUILD)
	rm -rf $(BUILD)/dri
	cp -r $(UTILS) $(BUILD)/dri
	$(MAKE) -C $(BUILD)/dri
	cp $(BUILD)/dri/bin/ed.com $@

$(BUILD)/cpm.img: $(DISKDEFS) $(BUILD)/devs.com $(BUILD)/term.com $(BUILD)/ed.com $(BUILD)/bootarea.bin $(HAWLEY)/zmac.com $(HAWLEY)/zml.com | $(BUILD)
	cp $(DISKDEFS) $(BUILD)/diskdefs
	cd $(BUILD) && mkfs.cpm -f sedna -b bootarea.bin cpm.img
	cd $(BUILD) && cpmcp -f sedna cpm.img devs.com 0:devs.com
	cd $(BUILD) && cpmcp -f sedna cpm.img term.com 0:term.com
	# Guest tools need CRLF and terminating 1Ah.
	sed -e 's/\r$$//' -e 's/$$/\r/' $(ASM)/devlib.inc > $(BUILD)/devlib.inc
	printf '\032' >> $(BUILD)/devlib.inc
	cd $(BUILD) && cpmcp -f sedna cpm.img devlib.inc 0:devlib.inc
	sed -e 's/\r$$//' -e 's/$$/\r/' $(ASM)/serial.inc > $(BUILD)/serial.inc
	printf '\032' >> $(BUILD)/serial.inc
	cd $(BUILD) && cpmcp -f sedna cpm.img serial.inc 0:serial.inc
	cd $(BUILD) && cpmcp -f sedna cpm.img ../../$(HAWLEY)/zmac.com 0:zmac.com
	cd $(BUILD) && cpmcp -f sedna cpm.img ../../$(HAWLEY)/zml.com 0:zml.com
	cd $(BUILD) && cpmcp -f sedna cpm.img ed.com 0:ed.com
	cd $(BUILD) && cpmls -f sedna cpm.img
	@test "$$(stat -c %s $@)" -le "$(CPMSIZE)" \
	  || { echo "cpm.img is larger than the diskdef geometry allows"; exit 1; }
	truncate -s $(CPMSIZE) $@	# mkfs.cpm writes only the used prefix

clean:
	rm -rf $(BUILD)

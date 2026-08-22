# Runs inside the container from Dockerfile; see build.gradle.kts. Everything lands in build/.

ASM      := src/main/asm
CPM22    := external/cpm22
BUILD    := build/cpm
DISKDEFS := src/main/diskdefs/diskdefs

# Derived from the diskdef rather than restated, so the image cannot silently disagree with it.
CPMSIZE := $(shell awk '/^[ \t]*tracks/{t=$$2} /^[ \t]*sectrk/{s=$$2} /^[ \t]*seclen/{l=$$2} END{print t*s*l}' src/main/diskdefs/diskdefs)

CCP_ORG  := 0E200h
BDOS_ORG := 0EA00h

.PHONY: all clean
all: $(BUILD)/bootrom.bin $(BUILD)/cpm.img

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/ccp.bin: $(CPM22)/ccp.asm | $(BUILD)
	asl -D origin=$(CCP_ORG),noserial,noserialize -o $(BUILD)/ccp.p -L -OLIST $(BUILD)/ccp.lst $<
	p2bin -l '$$00' -r '$$E200-$$E9FF' $(BUILD)/ccp.p

$(BUILD)/bdos.bin: $(CPM22)/bdos.asm | $(BUILD)
	asl -D origin=$(BDOS_ORG) -o $(BUILD)/bdos.p -L -OLIST $(BUILD)/bdos.lst $<
	p2bin -l '$$00' -r '$$EA00-$$F7FF' $(BUILD)/bdos.p

$(BUILD)/cbios.bin: $(ASM)/cbios.asm | $(BUILD)
	asl -i $(ASM) -o $(BUILD)/cbios.p -L -OLIST $(BUILD)/cbios.lst $<
	p2bin -l '$$00' -r '$$F800-$$FFFF' $(BUILD)/cbios.p

$(BUILD)/bootrom.bin: $(ASM)/bootrom.asm $(BUILD)/ccp.bin $(BUILD)/bdos.bin $(BUILD)/cbios.bin
	asl -i $(BUILD) -o $(BUILD)/bootrom.p -L -OLIST $(BUILD)/bootrom.lst $<
	p2bin -l '$$00' -r '$$0000-$$1FFF' $(BUILD)/bootrom.p

$(BUILD)/devs.com: $(ASM)/devs.asm $(ASM)/devlib.inc | $(BUILD)
	asl -i $(ASM) -o $(BUILD)/devs.p -L -OLIST $(BUILD)/devs.lst $<
	p2bin -l '$$00' $(BUILD)/devs.p
	mv $(BUILD)/devs.bin $@

# The image carries no system tracks; it is a data-only floppy the CBIOS mounts as A:.
# cpmtools looks for `diskdefs` in the working directory, so run it from there.
$(BUILD)/cpm.img: $(DISKDEFS) $(BUILD)/devs.com | $(BUILD)
	cp $(DISKDEFS) $(BUILD)/diskdefs
	cd $(BUILD) && mkfs.cpm -f sedna cpm.img
	cd $(BUILD) && cpmcp -f sedna cpm.img devs.com 0:devs.com
	cd $(BUILD) && cpmcp -f sedna cpm.img ../../$(ASM)/devlib.inc 0:devlib.inc
	cd $(BUILD) && cpmls -f sedna cpm.img
	@test "$$(stat -c %s $@)" -le "$(CPMSIZE)" \
	  || { echo "cpm.img is larger than the diskdef geometry allows"; exit 1; }
	truncate -s $(CPMSIZE) $@	# mkfs.cpm writes only the used prefix

clean:
	rm -rf $(BUILD)

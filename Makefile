TOOLCHAIN_FOLDER = ./toolchain/bin
WIN_EABI_GCC = $(TOOLCHAIN_FOLDER)/arm-none-eabi-gcc.exe
WIN_EABI_OBJCOPY = $(TOOLCHAIN_FOLDER)/arm-none-eabi-objcopy.exe
CARTRIDGE = ./zig-out/bin/cartridge.exe
MGBA = ./toolchain/mgba/mGBA.exe

.PHONY: all clean fclean compile emu

all:
	zig build

ifeq ($(OS),Windows_NT)
clean:
	-powershell -NoProfile -Command "Remove-Item -Force -ErrorAction SilentlyContinue *.bin,*.elf"

fclean: clean
	-powershell -NoProfile -Command "Remove-Item -Force -ErrorAction SilentlyContinue *.gba"
else
clean:
	rm -rf *.bin *.elf

fclean: clean
	find . -maxdepth 1 -type f -name "*.gba" -delete
endif

compile: all
	$(WIN_EABI_GCC) -mcpu=arm7tdmi -mlittle-endian -nostdlib -T gba.ld -o test.elf bootstrap.S
	$(WIN_EABI_OBJCOPY) -O binary ./test.elf ./test.bin
	$(CARTRIDGE) hdr gen -o ./test.gba -b ./test.bin

emu: compile
	$(MGBA) ./test.gba

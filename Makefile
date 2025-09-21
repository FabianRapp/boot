QEMU=qemu-system-i386
IMG=disk.img

all: $(IMG)

boot.bin: boot.asm
	nasm -f bin -o $@ $<

$(IMG): boot.bin
	dd if=/dev/zero of=$(IMG) bs=512 count=128
	dd if=boot.bin of=$(IMG) conv=notrunc


run: $(IMG)
	$(QEMU) -drive file=$(IMG),format=raw -no-reboot -no-shutdown

clean:
	rm -f boot.bin $(IMG)

re: clean $(IMG) run

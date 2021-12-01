CC = arm-linux-gnueabi-gcc

all: syscall move

syscall: syscall.c
	$(CC) -o syscall syscall.c

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo cp syscall ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall
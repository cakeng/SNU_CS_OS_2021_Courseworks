CC = arm-linux-gnueabi-gcc

all: syscall test move

syscall: syscall.c
	$(CC) -o syscall syscall.c
	
test: test.c
	$(CC) -o test test.c

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo cp syscall test ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall test
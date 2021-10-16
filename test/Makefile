CC = arm-linux-gnueabi-gcc

all: infloop syscall move

infloop: infloop.c
	$(CC) -o infloop infloop.c

syscall: syscall.c
	$(CC) -o syscall syscall.c

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo mv infloop syscall ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall infloop
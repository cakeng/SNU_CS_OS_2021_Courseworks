CC = arm-linux-gnueabi-gcc

all: syscall file_loc move

syscall: syscall.c
	$(CC) -o syscall syscall.c
file_loc: file_loc.c
	$(CC) -o file_loc file_loc.c

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo cp syscall file_loc ../proj4.fs ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall file_loc
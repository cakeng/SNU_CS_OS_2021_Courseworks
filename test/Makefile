CC = arm-linux-gnueabi-gcc

all: syscall test trial selector move

syscall: syscall.c
	$(CC) -o syscall syscall.c
	
test: test.c
	$(CC) -o test test.c

trial: trial.c
	arm-linux-gnueabi-gcc -o trial trial.c -lm

selector: selector.c
	$(CC) -o selector selector.c

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo cp syscall test selector trial ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall test selector trial
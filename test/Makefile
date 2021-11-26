CC = arm-linux-gnueabi-gcc

all: syscall test trial autorotation selector move

syscall: syscall.c
	$(CC) -o syscall syscall.c
	
test: test.c
	$(CC) -o test test.c

autorotation: autorotation.c
	$(CC) -o autorotation autorotation.c

trial: trial.c
	arm-linux-gnueabi-gcc -o trial trial.c -lm

selector: selector.c
	$(CC) -o selector selector.c

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo cp syscall test selector trial autorotation ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall test selector trial autorotation
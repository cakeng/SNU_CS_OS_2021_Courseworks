CC = arm-linux-gnueabi-gcc

all: infloop infloop_weight syscall  prime move

infloop: infloop.c
	$(CC) -o infloop infloop.c
	
infloop_weight: infloop_weight.c
	$(CC) -o infloop_weight2 infloop_weight.c

syscall: syscall.c
	$(CC) -o syscall syscall.c

prime: prime.c
	arm-linux-gnueabi-gcc -o prime prime.c -lm

move: 
	sudo mkdir mount
	sudo mount ../../tizen-image/rootfs.img ./mount
	sudo mv infloop syscall prime infloop_weight2 ./mount/root/
	sudo umount ./mount
	sudo rmdir mount

clean:
	rm -rf syscall infloop infloop_weight2 prime

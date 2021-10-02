#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>

int main()
{
    printf ("Calling syscall 398...\n");
	syscall(398, NULL, NULL);
    printf ("Called syscall 398. Terminating.\n");
	return 0;
}
![proj1_diagram](./proj1_diagram.PNG)

Use git clone to download proj1 brach  
Create tizen-image directory and unzip&copy the required image files. 
The directory structure would look like  

dir_root/
------osfall2021-team1-proj1/ 
------------qemu.sh  
------------generate.sh  
------------kernel/  
------------------ptree.c  
------------test/  
------------------mnt.sh   
------------------test_ptree.c  
------------------mount  
------------------a.out  
------tizen-image/  
------------img files   

------Building the OS------  
Entering osfall2021-team1-proj1 and directory run ./generate.sh  

------Building Test Files------  
Enter osfall2021-team1-proj1/test and make mount directory  
build with arm-linux-gnueabi-gcc test_ptree.c  
run ./mnt.sh to mount root image and copy the binary to the root directory in the mounted image.  

To run the VM, change directory to osfall2021-team1-proj1 and run ./qemu.sh  
After booting run the copied binary in the root user home directory.  

It will test 5 cases  
 1.     Normal cases it passes buf and nr returned from syscall  
 2.      nr NULL case => EINVAL  
 3.      buf NULL case => EINVAL  
 4.      nr less than 1 case  
 5.      Invalid access case => EFAULT  

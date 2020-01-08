# vdbench-performanc
Container and Scripts for running vdbench

The purpose of this project is to create a Performance-Test container with the vdbench benchmark.
Since the vdbench is tool that you need login to oracle for download it ( with no cost), i am not
adding it in this repo.

Vdbench can be downloaded from http://www.oracle.com/technetwork/server-storage/vdbench-downloads-1901681.html

the Current build of vdbench, which used in this repository is : 5.04.07
for building this container you can nedd to do :

    * clone this repository
    * download the vdbench from the oracle site.
    * unzip the download file.
    * in the directory that create (e.g. vdbench50407) do :
        - mv linux bin/
        - mv classes bin/
        - delete all other os's - that are not relevant to this conatiner.
    * download https://community.oracle.com/servlet/JiveServlet/downloadBody/1025084-102-1-177296/CollectSlaveStats.class and place it in the vdbench50407/classes/Vdb directory
    * move the scripts directory into vdbench50407 directory
    * run : docker build .

in the futer releas i will simplefy the procedure.

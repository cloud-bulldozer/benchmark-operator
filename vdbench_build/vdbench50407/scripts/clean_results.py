#!/usr/bin/env python3

'''
    This script is used for create a clean test results report.
    
    Author : Avi Liani <alayani@redhat.com>
    Created : Aug-29-2019
'''

import sys
import os

'''
    Setting the Base header line
'''

base_heder_line = ["interval", "IOPS", "Thoghtput", "BlockSize", "% Read",
                   "Latency", "R-Latency", "W-Latency", "Dev-Latency",
                   "QueueDepth", "%cpu-sys+u", "%cpu-sys" ]
'''
    verify that input filename passed to the script
'''
if len(sys.argv) > 1:
    file_name = sys.argv[1]
else:
    print ("Error: No input file !!!")
    sys.exit(1)
    
'''
    verify that the file is exist.
'''
if os.path.isfile(file_name) is not True:
    print ("Error: Input file dose not exist !")
    sys.exit(1)

'''
    the output file will be at the same location as the input file
'''
logdir = os.path.dirname(file_name)


'''
    splliting the file name to create the output filename
    with differen extention.
'''
output_filename = os.path.splitext(os.path.basename(file_name))[0]
output_filename = logdir + "/" + output_filename + ".clean.log"


print ("Input file name is {}".format(file_name))
print ("Output file name is {}".format(output_filename))

'''
    Setting up file handleres for output files
'''
out_file = open(output_filename, "w")

start_section = 0 # this will tell the script to print the output

'''
    read the input file and cleanup the unnecceray data
'''
with open(file_name, "r") as fh:
    line = fh.readline()
    while line:
        
        # Getting test results
        if ":" in line and start_section > 0:
            results = line.strip().split()
            del results[9:11]
            
            if "avg" in line:
                results[1] = "AVG"
                start_section = 0

            out_file.write(','.join(results) + "\n")

        # Getting the test name (RD) from the log
        if "Starting RD" in line:
            rd = line.split(';')[0].split('=')[-1]
            iorate = line.split(';')[1].split(':')[-1]
            out_file.write("{},IORATE={}\n".format(rd,iorate))
            start_section = 1
        
        # start the test results section with header
        if "interval" in line and start_section ==1:
            t_date = line[:12].replace(', ','-').replace(' ','-')
            out_file.write(t_date + "," + ",".join(base_heder_line) + "\n")
            line = fh.readline()    # read the second line header.
            start_section = 2
        
            
        line = fh.readline()

'''
    make sure the FileHandlers closed.
'''
fh.close()
out_file.close()

#!/usr/bin/python3.4


import argparse
import glob
import os
import re
import sys
import time
from subprocess import call

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--incr0", help="Check incremental level 0", action="store_true")
parser.add_argument("-i", "--incr1", help="Check incremental level 1", action="store_true")
parser.add_argument("-a", "--arch", help="Check backup archivelogs", action="store_true")
args = parser.parse_args()


# If path to log files different, change "dir" variable.
dir = "/root/test/"
err = [r"RMAN\-+.+\n", r"ORA\-+.+\n"]


# Functions
# Check directory
def directory():
    dir_exist = os.path.exists(dir)
    if not dir_exist:
        print("CRITICAL - Directory doesn't exist!")
        sys.exit(4)
    else:
        os.chdir(dir)


# Check if file is missing
def missing():
    for log in file:
        t = os.stat(', '.join(log))
        c = t.st_ctime
        if c < old:
            print("CRITICAL - File is missing!")
            sys.exit(3)


# Check if file is empty
def empty():
    null = os.stat(', '.join(file)).st_size
    if null == 0:
        print("CRITICAL - File is empty")
        sys.exit(2)


# Check backup incremental level 0.
# Change "db0*" if log file has another name.
if args.incr0:
    directory()
    now = time.time()
    old = now-(7*84600)
    file = glob.glob(dir+"db0*")
    missing()
    empty()
    with open(', '.join(file), 'r') as file:
        list = file.read()
        linerman = re.findall(err[0], list)
        lineora = re.findall(err[1], list)
        if linerman:
            print("CRITICAL - backup failed:\n "+(', '.join(linerman))+(', '.join(lineora)))
            sys.exit(1)
        else:
            print("OK - backup complete.")
            sys.exit(0)


# Check backup incremental level 1
# Change "db1*" if log file has another name.
if args.incr1:
    directory()
    now = time.time()
    old = now-86400
    file = glob.glob(dir+"db1*")
    missing()
    empty()

    with open(', '.join(file), 'r') as file:
        list = file.read()
        linerman = re.findall(err[0], list)
        lineora = re.findall(err[1], list)
        if linerman:
            print("CRITICAL - backup failed:\n "+(', '.join(linerman))+(', '.join(lineora)))
            sys.exit(1)
        else:
            print("OK - backup complete.")
            sys.exit(0)


# Check backup archivelogs
# Change "arc*" if log file has another name.
if args.arch:
    directory()
    now = time.time()
    old = now-3600
    file = glob.glob(dir+"arc*")
    missing()
    empty()

    with open(', '.join(file), 'r') as file:
        list = file.read()
        linerman = re.findall(err[0], list)
        lineora = re.findall(err[1], list)
        if linerman:
            print("CRITICAL - backup failed:\n "+(', '.join(linerman))+(', '.join(lineora)))
            sys.exit(1)
        else:
            print("OK - backup complete.")
            sys.exit(0)

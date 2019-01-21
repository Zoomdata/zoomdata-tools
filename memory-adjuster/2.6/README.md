# Copyright (C) Zoomdata, Inc. 2012-2019. All rights reserved.

# Zoomdata Memory (JVM) Adjustment Script

## Purpose
This script sets the JVM memory allocation for the following Zoomdata 2.6 component services

## Parameters
The script accepts the following parameters:

| Parameter |  Required  |  Description  |  Default  |
| --- | --- | --- | --- |
| allowed_mem | No | Total amount of host memory (in MB) that should be allocated to Zoomdata | Total available to the host instance, minus 15%

## Options
The script accepts the following options as `--option=value`:

| Option |  Description  |  Default  |
| --- | --- | --- |
| config-dir | Config dir to put `<component>.env` files | /etc/zoomdata
| install-path | Zoomdata installation folder | /opt/zoomdata
| verbose | Allow extended output | 

## Usage
```
./memory-adjuster.py -h
Usage: memory-adjuster.py [options] allowed_mem
  Script to auto adjust memory settings for Zoomdata application and components.
Options:
  -h, --help            show this help message and exit
  --config-dir=CONFIG_LOCATION
                        Config dir to put <component>.env files. Default: /etc/zoomdata
  --install-path=INSTALL_LOCATION
                        Zoomdata installation folder
  --verbose             Allow extended output
```

### Deployment on dedicated resources
Use the following example when allocating all of the host memory to Zoomdata. The script will reserve 15% of the host's total memory for the OS by default.
```
./memory-adjuster.py
```

### Deployment on shared resources
Use the following example when allocating a specific amount of memory to Zoomdata. This example allocates 20 GB and makes no reservation for non-Zoomdata processes.
```
./memory-adjuster.py 20480
```

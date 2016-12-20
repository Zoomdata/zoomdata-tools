#Zoomdata Memory (JVM) Adjustment Script

##Purpose
This script sets the JVM memory allocation for the following Zoomdata 2.3 component services
- Zoomdata (application server)
- Job Scheduler
- Spark Proxy (SparkIt cache)
- Elasticsearch (1.7) connector
- Demo Datasource (Real Time Sales)

##Parameters
The script accepts the following parameters:

| Parameter |  Required  |  Description  |  Default  |
| --- | --- | --- | --- |
| allowed_mem | No | Total amount of host memory (in MB) that should be allocated to Zoomdata | Total available to the host instance, minus 15%

##Options
The script accepts the following options as `--option=value`:

| Option |  Description  |  Default  |
| --- | --- | --- |
| config-dir | Host directory where Zoomdata component `.env` files reside | /etc/zoomdata
| edcs-count | The number of running connection servers (EDC) on the instance | 17
| os-reserved | The percentage of host memory that will be reserved for system (non-Zoomdata) processes | 15

##Usage
```
./memory-adjuster.py -h
Usage: memory-adjuster.py [options] allowed_mem

  Script to auto adjust memory settings for Zoomdata application and components.

  allowed_mem  - Amount of memory in Mb allowed to use by Zoomdata.
                 Total instance memory will be used by default.

Options:
  -h, --help            show this help message and exit
  --config-dir=CONFIG_DIR
                        Config dir to put <component>.env files. Default:
                        /etc/zoomdata
  --edcs-count=EDCS_COUNT
                        EDC servers count running on this host. Default: 17
  --os-reserved=OS_RESERVED
                        Percent of memory reserved for OS. Default: 15%
```

###Deployment on dedicated resources
Use the following example when allocating all of the host memory to Zoomdata. The script will reserve 15% of the host's total memory for the OS by default.
```
./memory-adjuster.py
```

###Deployment on shared resources
Use the following example when allocating a specific amount of memory to Zoomdata. This example allocates 20 GB and makes no reservation for non-Zoomdata processes.
```
./memory-adjuster.py --os-reserved=0 20480
```

#Zoomdata Memory (JVM) Adjustment Script

##Purpose
This script sets the JVM memory allocation for the following Zoomdata 2.3 component services
- Zoomdata (application server)
- Job Scheduler
- Spark Proxy (SparkIt cache)
- Elasticsearch (1.7) connector
- Demo Datasource (Real Time Sales)

##Parameters
The script accepts the following parameters
1. Memory (required) - Total amount of host memory (in KB) that should be allocated to Zoomdata
2. Non-product memory reservation (optional) - The percentage of host memory that will be reserved for system (non-Zoomdata) processes. By default this is set to `15`.

Using the parameters above, total memory available to Zoomdata is computed by: 
`"Memory" * (100 - "Non-product memory reservation") / 100)`

##Usage
###Deployment on dedicated resources
Use the following example when allocating all of the host memory to Zoomdata. The script will reserve 15% of the host's total memory for the OS by default.
```
./memory-adjuster.py `/usr/bin/cat /proc/meminfo |/bin/grep "MemTotal" | /usr/bin/awk '{print $2}'`
```

###Deployment on shared resources
Use the following example when allocating a specific amount of memory to Zoomdata. This example allocates 20 GB and reserves none of it for non-Zoomdata processes.
```
./memory-adjuster.py 20971520 0
```

# LL-Tracket
Low-level Application Performance and Memory Tracket

## Introduction

I needed an utility to allow me to measure the maximum memory allocation during the execution of an application.
This is it, it will give you the maximum memory size used by an application, plot it if needed and generate a JSON file with the data.

## Usage

To analyse the amount of memory used by the JetStream2 benchmark when ran with WebKit's JSC I ran from the JetStream2 benchmark folder:

``` 
$ racket ~/Projects/ll-tracket/main.rkt ../../WebKitBuild/Release/bin/jsc -e "testList=['WSL']" cli.js
Page size for your system is 4096 bytes
Tracking process 26636
Starting JetStream2
Running WSL:
    Stdlib: 1.334
    Tests: 0.471
    Score: 0.793
    Wall time: 0:14.379


Stdlib: 1.334
MainRun: 0.471

Total Score:  0.793 

Process finished (in 14434.0ms), gathered 7132 records
Maximum virtual memory used: 1885.32Mb
```

This will probably only work on Linux at the moment due to the way I get the page size (using `getpagesize`). I am happy to get PRs to make it portable.

I have double-checked these values with [`recidivm`](https://github.com/jwilk/recidivm) (suggested by `afl-fuzz`).
For example, for the same run above:

```
$ /home/pmatos/Projects/recidivm-0.2/recidivm ../../WebKitBuild/Release/bin/jsc -e "testList=['WSL']" cli.js
1853739008
```

As you can see they provide very close values. They will never be precise or exactly the same due to the way Linux does memory allocation. We are measuring virtual memory assigned to the process calculated in pages. For example, if you allocate 10bytes the system will grant you at least a page, which on my system is 4096 bytes therefore even though the accurate memory requested is 10bytes, the application will report 4096 bytes as being allocated by the application (the memory page is the atomic unit of allocation in a virtual memory OS).


#!/bin/bash

TRACEFILE="$1"
if [ -z "$TRACEFILE" ]; then
  echo "Usage: $0 tracefile"
  exit 1
fi

# 1. Extract only “r” (received) events, along with timestamp.
#    We’ll assume the timestamp is the field after “-t”.
#    Example: r -t 0.514 … → timestamp = 0.514

# awk to parse:
awk '
  # Only consider lines beginning with “r”
  $1 == "r" {
    # Find the “-t” flag and get the next field as timestamp
    for (i = 1; i <= NF; i++) {
      if ($i == "-t") {
        ts = $(i+1)
      }
      # Also find packet size field (“-e size”)
      if ($i == "-e") {
        pkt_size = $(i+1)
      }
    }
    # record timestamp, size
    times[++count] = ts
    sizes[count] = pkt_size
  }
  
  END {
    if (count < 1) {
      print "No received packets found."
      exit
    }
    # total data in bytes = sum of sizes
    total_bytes = 0
    for (i = 1; i <= count; i++) {
      total_bytes += sizes[i]
    }
    # convert to bits
    total_bits = total_bytes * 8

    # time interval
    tstart = times[1]
    tend = times[count]
    duration = tend - tstart

    printf("First receive timestamp = %.6f s\n", tstart)
    printf("Last receive timestamp = %.6f s\n", tend)
    printf("Duration = %.6f s\n", duration)
    printf("Total received packets = %d\n", count)
    printf("Total bytes = %d bytes\n", total_bytes)
    printf("Total bits = %d bits\n", total_bits)

    if (duration > 0) {
      thr = total_bits / duration
      # print in bps and Mbps
      printf("Effective throughput = %.3f bps  (%.3f Mbps)\n", thr, thr/1e6)
    } else {
      print "Zero duration, throughput undefined."
    }
  }
' "$TRACEFILE"

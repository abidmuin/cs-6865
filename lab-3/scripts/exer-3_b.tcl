# Exercise 3(b): TCP/FTP competing with CBR/UDP

# Create simulator
set ns [new Simulator]

# Define colors for flows (this affects NAM visualization)
$ns color 0 Blue;   # TCP
$ns color 1 Red;    # CBR

# Create NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

# Create trace file for analysis
set tracefile [open out.tr w]
$ns trace-all $tracefile

# Create Xgraph output files
set f0 [open out0.tr w];    # TCP
set f1 [open out1.tr w];    # CBR

# Create nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

# Connect nodes (1Mbps, 10ms, DropTail)
$ns duplex-link $n0 $n2 1Mb 10ms DropTail
$ns duplex-link $n1 $n2 1Mb 10ms DropTail
$ns duplex-link $n2 $n3 1Mb 10ms DropTail
$ns duplex-link $n3 $n4 1Mb 10ms DropTail
$ns duplex-link $n3 $n5 1Mb 10ms DropTail

# Orient links for better visualization
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n5 orient right-down


# Flow 0: TCP / FTP (n0 -> n4)
set tcp0 [new Agent/TCP]
$tcp0 set class_ 0
$tcp0 set window_ 100
$tcp0 set packetSize_ 500
$ns attach-agent $n0 $tcp0

set sink0 [new Agent/TCPSink]
$ns attach-agent $n4 $sink0

$ns connect $tcp0 $sink0

set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0


# Flow 1: CBR / UDP (n1 -> n5)
set udp1 [new Agent/UDP]
$udp1 set class_ 1
$ns attach-agent $n1 $udp1

set sink1 [new Agent/LossMonitor]
$ns attach-agent $n5 $sink1

$ns connect $udp1 $sink1

set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 500
$cbr1 set interval_ 0.005     ;# 800 Kbps
$cbr1 attach-agent $udp1


# Record throughput for Xgraph
proc record {} {
    global ns f0 f1 sink0 sink1

    set timeInterval 0.5
    set now [$ns now]

    # Calculate throughput (Mbps)
    set bw0 [expr [$sink0 set bytes_]*8.0/($timeInterval*1000000)]
    set bw1 [expr [$sink1 set bytes_]*8.0/($timeInterval*1000000)]

    puts $f0 "$now $bw0"
    puts $f1 "$now $bw1"

    # Reset counters for next interval
    $sink0 set bytes_ 0
    $sink1 set bytes_ 0

    $ns at [expr $now+$timeInterval] "record"
}


$ns at 0.0 "record"

# Flow start/stop times
# n0-n4
$ns at 1.0 "$ftp0 start"
$ns at 20.0 "$ftp0 stop"
# n1-n5
$ns at 5.0 "$cbr1 start"
$ns at 15.0 "$cbr1 stop"

# Finish routine
proc finish {} {
    global ns nf f0 f1 tracefile

    $ns flush-trace
    close $tracefile
    close $f0
    close $f1
    close $nf

    exec xgraph out0.tr out1.tr -geometry 1920x1080 -x "Time (s)" -y "Throughput (Mbps)" &
    exec nam out.nam &
    exit 0
}

# Call finish at end of simulation
$ns at 25.0 "finish"

# Run simulation
$ns run
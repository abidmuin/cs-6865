# =========================
# Exercise 2: Two Competing CBR Flows
# =========================

# Create a simulator object
set ns [new Simulator]

# Define colors for flows (this affects NAM visualization)
$ns color 0 Red
$ns color 1 Blue

# Create NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

# Create Xgraph output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]

# =========================
# Create nodes
# =========================
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

# =========================
# Connect nodes (1Mbps, 10ms, DropTail)
# =========================
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

# =========================
# Create traffic sinks
# =========================
set sink0 [new Agent/LossMonitor]
$ns attach-agent $n4 $sink0

set sink1 [new Agent/LossMonitor]
$ns attach-agent $n5 $sink1

# =========================
# Create UDP agents and CBR sources
# =========================
# Flow 0: n0 -> n4
set udp0 [new Agent/UDP]
$udp0 set class_ 0
$ns attach-agent $n0 $udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.005     ;# 800 Kbps
$cbr0 attach-agent $udp0
$ns connect $udp0 $sink0

# Flow 1: n1 -> n5
set udp1 [new Agent/UDP]
$udp0 set class_ 1
$ns attach-agent $n1 $udp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 500
$cbr1 set interval_ 0.005     ;# 800 Kbps
$cbr1 attach-agent $udp1
$ns connect $udp1 $sink1

# =========================
# Record throughput for Xgraph
# =========================
proc record {} {
    global ns sink0 sink1 f0 f1
    set time 0.5
    set now [$ns now]

    set bw0 [$sink0 set bytes_]
    set bw1 [$sink1 set bytes_]
    puts $f0 "$now [expr $bw0/$time*8/1000000]"
    puts $f1 "$now [expr $bw1/$time*8/1000000]"
    
    $sink0 set bytes_ 0
    $sink1 set bytes_ 0
    $ns at [expr $now+$time] "record"
}

$ns at 0.0 "record"

# =========================
# Start and stop flows
# =========================
$ns at 1.0 "$cbr0 start"
$ns at 20.0 "$cbr0 stop"

$ns at 5.0 "$cbr1 start"
$ns at 15.0 "$cbr1 stop"

# =========================
# Finish procedure
# =========================
proc finish {} {
    global f0 f1 nf
    close $f0
    close $f1
    close $nf
    
    exec xgraph out0.tr out1.tr -geometry 800x400 &
    exec nam out.nam &
    exit 0
}

# Call finish at end of simulation
$ns at 25.0 "finish"

# =========================
# Run simulation
# =========================
$ns run

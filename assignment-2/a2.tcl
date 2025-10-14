# NS2 simulation of a real-world traceroute path to www.kuet.ac.bd (172.67.170.169)
# Based on 12-hop traceroute output captured on Linux using UDP
# Simulates a UDP traffic flow (CBR) from source to destination through 12 routers

# Create a new Simulator instance
set ns [new Simulator]

# Open trace file for packet-level event logging
set tf [open a2.tr w]
$ns trace-all $tf

# Open NAM trace file for network animation
set nf [open a2.nam w]
$ns namtrace-all $nf

# ---------------------
# Define 13 nodes total (1 source, 1 destination, 11 intermediate routers)
# Each node corresponds to a hop in the traceroute output
# ---------------------
set n0 [$ns node]  ;# Source
set n1 [$ns node]  ;# Hop 1: 10.9.64.2
set n2 [$ns node]  ;# Hop 2: 10.8.2.38
set n3 [$ns node]  ;# Hop 3: 10.8.2.33
set n4 [$ns node]  ;# Hop 4: 198.164.163.49
set n5 [$ns node]  ;# Hop 5: 142.166.167.193
set n6 [$ns node]  ;# Hop 6: ae31.dr02.fctn.nb.bellaliant.net
set n7 [$ns node]  ;# Hop 7: ae7.cr02.stjh.nb.aliant.net
set n8 [$ns node]  ;# Hop 8: ae0.bx01.toro.on.aliant.net (Toronto)
set n9 [$ns node]  ;# Hop 9: ae8.bx01.chcg.il.aliant.net (Chicago)
set n10 [$ns node] ;# Hop 10: 13335.chi.equinix.com
set n11 [$ns node] ;# Hop 11: 141.101.73.X (Cloudflare edge)
set n12 [$ns node] ;# Destination: www.kuet.ac.bd (172.67.170.169)

# ---------------------
# Define consistent bandwidth for all links
# This represents the link capacity — here, we use 45 Mbps
# ---------------------
set bw 45Mb

# ---------------------
# Define duplex links between each consecutive pair of nodes
# Delays are based on estimated one-way delays from delta RTTs
# ---------------------
$ns duplex-link $n0 $n1 $bw 3.62ms DropTail
$ns duplex-link $n1 $n2 $bw 1.17ms DropTail
$ns duplex-link $n2 $n3 $bw 0.1ms DropTail
$ns duplex-link $n3 $n4 $bw 1.46ms DropTail
$ns duplex-link $n4 $n5 $bw 0.1ms DropTail
$ns duplex-link $n5 $n6 $bw 0.1ms DropTail
$ns duplex-link $n6 $n7 $bw 1.44ms DropTail
$ns duplex-link $n7 $n8 $bw 18.16ms DropTail
$ns duplex-link $n8 $n9 $bw 9.43ms DropTail
$ns duplex-link $n9 $n10 $bw 6.12ms DropTail
$ns duplex-link $n10 $n11 $bw 9.85ms DropTail
$ns duplex-link $n11 $n12 $bw 0.1ms DropTail

# ---------------------
# Setup UDP traffic from source (n0) to destination (n12)
# ---------------------

# Create a UDP agent and attach it to the source node
set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0

# Create a Null agent (acts as data sink) at the destination node
set null0 [new Agent/Null]
$ns attach-agent $n12 $null0

# Connect the UDP agent to the Null agent
$ns connect $udp0 $null0

# ---------------------
# Setup a Constant Bit Rate (CBR) traffic generator
# CBR is useful to simulate steady traffic flow (e.g., VoIP, sensor data)
# ---------------------
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 512         ;# Packet size in bytes
$cbr0 set interval_ 0.05          ;# Time between packets (seconds)
$cbr0 attach-agent $udp0          ;# Attach to the UDP agent at source

# ---------------------
# Schedule simulation events
# Start and stop traffic, then end simulation
# ---------------------
$ns at 0.5 "$cbr0 start"          ;# Start sending CBR packets at time 0.5s
$ns at 4.5 "$cbr0 stop"           ;# Stop sending CBR packets at time 4.5s
$ns at 5.0 "finish"               ;# End the simulation at time 5.0s

# ---------------------
# Define finish procedure to close files and launch NAM
# ---------------------
proc finish {} {
    global ns nf tf
    $ns flush-trace
    close $nf
    close $tf
    exec nam a2.nam &            ;# Launch Network Animator (NAM) GUI
    exit 0
}

# Run the simulation
$ns run

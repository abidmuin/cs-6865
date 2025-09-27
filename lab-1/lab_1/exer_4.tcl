# template start
set ns [new Simulator]

set nf [open exer_4.nam w]
$ns namtrace-all $nf


# template end

# Node and link creation start
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]

$ns duplex-link $n0 $n1 1Mb 10ms DropTail
$ns duplex-link $n1 $n2 1Mb 10ms DropTail
# Node and link creation end

# Sending data start
#Create a UDP agent and attach it to node n0
set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0

# Create a CBR traffic source and attach it to udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.005
$cbr0 attach-agent $udp0


set null0 [new Agent/Null] 
$ns attach-agent $n2 $null0

$ns connect $udp0 $null0

$ns at 0.5 "$cbr0 start"
$ns at 4.5 "$cbr0 stop"

# template start
proc finish {} {
        global ns nf
        $ns flush-trace
        close $nf
        exec nam exer_4.nam &
        exit 0
}

$ns at 5.0 "finish"

$ns run
#template end
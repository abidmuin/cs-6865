# Create a simulator object
set ns [new Simulator]

# Open the nam trace file
set nf [open exer_2_1.nam w]
$ns namtrace-all $nf

# Define a 'finish' procedure
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam exer_2_1.nam &
    exit 0
}

# Create two nodes
set n0 [$ns node]
set n1 [$ns node]

# Create a duplex link between the nodes
$ns duplex-link $n0 $n1 1Mb 10ms DropTail

# Create a TCP agent and attach it to node n0
set tcp0 [new Agent/TCP]
$tcp0 set packetSize_ 500         ;# Set packet size to 500
$tcp0 set window_ 1               ;# Set max window size to 1
$ns attach-agent $n0 $tcp0

# Create a TCP Sink agent and attach it to node n1
set sink0 [new Agent/TCPSink]
$ns attach-agent $n1 $sink0

# Connect the TCP agent to the sink
$ns connect $tcp0 $sink0

# Create an FTP application and attach it to the TCP agent
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

# Start the FTP traffic at 0.5s
$ns at 0.5 "$ftp0 start"

# Call the finish procedure at 5.0s
$ns at 5.0 "finish"

# Run the simulation
$ns run

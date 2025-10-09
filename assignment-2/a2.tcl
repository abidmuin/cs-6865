# Simulator object
set ns [new simulator]

# Different colors for data flows
$ns color 1 Blue
$ns color 2 Red

# Open the nam trace file
set nf [open a2.nam w]
$ns namtrace-all $nf

# Finish procedure
proc finish {} {
	global ns nf
	$ns flush-trace
	close $nf
	exec nam a2.nam &
	exit 0
}

# Node setup
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]
set n7 [$ns node]
set n8 [$ns node]
set n9 [$ns node]
set n10 [$ns node]
set n11 [$ns node]

# Links
$ns duplex-link $n0 $n1 43.36Mb 3.62ms DropTail
$ns duplex-link $n1 $n2 43.36Mb 4.79ms DropTail
$ns duplex-link $n2 $n3 43.36Mb 3.05ms DropTail
$ns duplex-link $n3 $n4 43.36Mb 4.51ms DropTail
$ns duplex-link $n4 $n5 43.36Mb 4.41ms DropTail
$ns duplex-link $n5 $n6 43.36Mb 3.62ms DropTail
$ns duplex-link $n6 $n7 43.36Mb 5.06ms DropTail
$ns duplex-link $n7 $n8 43.36Mb 23.22ms DropTail
$ns duplex-link $n8 $n9 43.36Mb 32.65ms DropTail
$ns duplex-link $n9 $n10 43.36Mb 3.62ms DropTail
$ns duplex-link $n10 $n11 43.36Mb 3.62ms DropTail



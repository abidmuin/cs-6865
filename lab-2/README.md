# LAB 2

## Exercise 1

### 1.1

```tcl
#Create a simulator object
set ns [new Simulator]

#Open the nam trace file
set nf [open exer11.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
        global ns nf
        $ns flush-trace
	#Close the trace file
        close $nf
	#Execute nam on the trace file
        exec nam exer11.nam &
        exit 0
}

#Create two nodes
set n0 [$ns node]
set n1 [$ns node]

#Create a duplex link between the nodes
$ns duplex-link $n0 $n1 1Mb 10ms DropTail

#Create a UDP agent and attach it to node n0
set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0

# Create a CBR traffic source and attach it to udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.005
$cbr0 attach-agent $udp0

#Create a Null agent (a traffic sink) and attach it to node n1
set null0 [new Agent/Null]
$ns attach-agent $n1 $null0

#Connect the traffic source with the traffic sink
$ns connect $udp0 $null0  

#Schedule events for the CBR agent
$ns at 0.5 "$cbr0 start"
$ns at 4.5 "$cbr0 stop"
#Call the finish procedure after 5 seconds of simulation time
$ns at 5.0 "finish"

#Run the simulation
$ns run
```

### 1.2

Timestamp (last packet) = 4.51399999999993
Timestamp (first packet) = 0.5
Packet send duration = (4.51399999999993 - 0.5) = 4.014

Packet transferred = (800 x 500) = 400,000 bytes x 8 = 3200000 bytes

Throughput = (3200000 / 4.014) = 797209.76582 bps = 0.8 Mbps
Bandwidth
```tcl
l -t * -s 0 -d 1 -S UP -r 1000000 -D 0.01 -c black
```
First and last Packet
```tcl
+ -t 0.5 -s 0 -d 1 -p cbr -e 500 -c 0 -i 0 -a 0 -x {0.0 1.0 0 ------- null}

r -t 4.51399999999993 -s 0 -d 1 -p cbr -e 500 -c 0 -i 800 -a 0 -x {0.0 1.0 800 ------- null}
```

### 1.3

Packet (frame) size = 500 bytes
Sending interval = 0.005 ms

Packet transferred = (500 bytes x 8) = 4000 bits

Theoretical Throughput = (4000 / 0.005 ) bps = 800000 bps = 0.8 Mbps

| **Metric**                      | **Exercise 1.2**              | **Exercise 1.3 (This One)**      |
| ------------------------------- | ----------------------------- | -------------------------------- |
| Packet Size                     | 500 bytes                     | 500 bytes                        |
| Sending Interval                | 0.005 seconds                 | 0.005 seconds                    |
| Simulation Time                 | 4.0 seconds of active traffic | 4.0 seconds                      |
| Theoretical Throughput          | 0.8 Mbps                      | 0.8 Mbps                         |
| Actual Throughput (if measured) | 0.8 Mbps (assuming no loss)   | 0.8 Mbps (also assuming no loss) |
| Congestion/Delay Model          | None (simple link)            | None (same simple link)          |


---

### ✅ Lab Exercise Comparison and Analysis: Stop-and-Wait TCP Flow vs. Original UDP/CBR Flow

---

### 💡 **Objective**

Compare the behavior of a **Stop-and-Wait TCP flow** (from Exercise 2.1) with the **original CBR over UDP flow** (from Exercise 1.1) by observing the traffic in **NAM** (Network Animator) in **slow motion**, identifying **key differences in traffic patterns**, and presenting the **new source code** with a **simulation screenshot**.

---

## 📘 1. Summary of Each Simulation

### 🔹 **Exercise 1.1 - CBR over UDP**

* **Protocol Used:** UDP (connectionless)
* **Traffic Type:** CBR (Constant Bit Rate)
* **No congestion control**, no packet loss detection.
* **Data Flow:** Continuous stream of packets from sender to receiver.
* **Packet Behavior:** Even spacing, uniform flow regardless of network conditions.

### 🔹 **Exercise 2.1 - Stop-and-Wait TCP (Window size = 1)**

* **Protocol Used:** TCP (connection-oriented)
* **Application:** FTP over TCP
* **Window Size:** 1 (effectively stop-and-wait behavior)
* **Traffic Type:** Reliable, sequential delivery
* **Packet Behavior:** One packet sent at a time, waits for ACK before sending the next.

---

## 🔍 2. Observations from NAM (in slow motion)

### 🟢 **CBR/UDP (Exercise 1.1):**

* Packets are sent at **regular intervals** (every 0.005s).
* No waiting for acknowledgments.
* High throughput.
* Sender keeps sending packets regardless of delivery success.
* Traffic is **dense and steady**.

### 🔴 **Stop-and-Wait TCP (Exercise 2.1):**

* Packets are sent **one at a time**.
* The sender **waits for ACK** from the receiver before sending the next packet.
* Noticeable **gaps between packets** in the animation.
* TCP shows **reliable delivery** with feedback loop.
* Traffic is **sparse and slow** due to waiting.

---

## 🧠 3. **Main Difference in Traffic Pattern**

> ✅ **The main difference** is in the **flow behavior**:
>
> **UDP/CBR** sends data at a **constant rate**, regardless of the receiver's state, while **TCP (Stop-and-Wait)** sends **one packet at a time**, waiting for an acknowledgment before sending the next.
>
> This results in a **dense, continuous flow** in Exercise 1.1 and a **slow, staggered flow** in Exercise 2.1.

---

## 📝 4. New Source Code (Exercise 2.1 - Stop-and-Wait TCP)

```tcl
# Create a simulator object
set ns [new Simulator]

# Open the nam trace file
set nf [open exer11.nam w]
$ns namtrace-all $nf

# Define a 'finish' procedure
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam exer11.nam &
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
```

---

## 📸 5. Screenshot: **"Stop and Wait TCP Flow Example"**

Please include this screenshot in your lab report:

> 🔻 **Suggested Screenshot to Capture in NAM:**
>
> * After running `nam exer11.nam`, **pause around 1s to 2s**.
> * Observe the **gaps between packets**.
> * Show the **ACKs returning** from the sink to the sender.
> * Save and label the screenshot as:
>   `"stop_and_wait_tcp_flow_example.png"`

If you want, you can send me the NAM screenshot and I can help annotate or verify it.

---

## ✅ Conclusion

* **CBR/UDP** is faster but lacks control and reliability.
* **TCP (Stop-and-Wait)** is slower but ensures reliable delivery.
* **Key Difference:** **Rate of flow and acknowledgment mechanism.**
* This experiment shows how **transport protocols** dramatically affect traffic behavior in a network.


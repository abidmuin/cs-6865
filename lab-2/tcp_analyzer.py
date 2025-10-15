import os
import sys


def analyze_trace_file(filename):
    """Analyze ns-2 trace file and calculate throughput"""

    if not os.path.exists(filename):
        print(f"Error: File '{filename}' not found!")
        return

    print(f"Analyzing trace file: {filename}")
    print("=" * 80)

    # Storage for analysis
    packets = []
    first_data_time = None
    last_data_time = None

    # Read and parse the trace file
    with open(filename, 'r') as file:
        for line_num, line in enumerate(file, 1):
            line = line.strip()
            if not line:
                continue

            # Parse packet events (+, -, h, r)
            if line.startswith(('+', '-', 'h', 'r')):
                try:
                    parts = line.split()
                    if len(parts) < 15:
                        continue

                    event_type = parts[0]
                    timestamp = float(parts[2])
                    src = int(parts[4])
                    dst = int(parts[6])
                    pkt_type = parts[8]
                    pkt_size = int(parts[10])
                    seq_num = int(parts[14])

                    packet_info = {
                        'event': event_type,
                        'time': timestamp,
                        'src': src,
                        'dst': dst,
                        'type': pkt_type,
                        'size': pkt_size,
                        'seq': seq_num,
                        'line': line,
                        'line_num': line_num
                    }

                    packets.append(packet_info)

                    # Find first data packet (TCP from node 0 to 1, size 540)
                    if (event_type == '+' and src == 0 and dst == 1
                            and pkt_type == 'tcp' and pkt_size == 540
                            and first_data_time is None):
                        first_data_time = timestamp
                        print(f"First data packet: seq={seq_num}, time={timestamp:.6f}s")

                    # Find last successfully received data packet
                    if (event_type == 'r' and dst == 1 and pkt_type == 'tcp'
                            and pkt_size == 540):
                        last_data_time = timestamp

                except (ValueError, IndexError) as e:
                    print(f"Warning: Could not parse line {line_num}: {line}")
                    continue

    if not packets:
        print("No packet events found in the trace file!")
        return

    # Calculate throughput
    if first_data_time is None or last_data_time is None:
        print("Error: Could not find data packets in the trace file!")
        return

    duration = last_data_time - first_data_time

    # Count successfully received data packets (540 bytes) from node 0 to 1
    received_data_packets = []
    for pkt in packets:
        if (pkt['event'] == 'r' and pkt['dst'] == 1 and
                pkt['type'] == 'tcp' and pkt['size'] == 540):
            received_data_packets.append(pkt)

    # Remove duplicates (same seq number)
    unique_received = {}
    for pkt in received_data_packets:
        unique_received[pkt['seq']] = pkt

    num_data_packets = len(unique_received)

    if num_data_packets == 0:
        print("Error: No data packets were successfully received!")
        return

    # Calculate payload bits (assuming 40 bytes TCP header)
    payload_per_packet = 540 - 40  # 500 bytes payload
    total_payload_bytes = num_data_packets * payload_per_packet
    total_payload_bits = total_payload_bytes * 8

    throughput_bps = total_payload_bits / duration
    throughput_kbps = throughput_bps / 1000
    throughput_mbps = throughput_bps / 1000000

    # Additional statistics
    tcp_data_sent = len([p for p in packets if p['event'] == '+' and p['src'] == 0
                         and p['type'] == 'tcp' and p['size'] == 540])
    tcp_data_received = len(unique_received)
    ack_sent = len([p for p in packets if p['event'] == '+' and p['type'] == 'ack'])

    # Packet loss calculation
    loss_rate = 0
    if tcp_data_sent > tcp_data_received:
        loss_rate = (tcp_data_sent - tcp_data_received) / tcp_data_sent * 100

    # Find sequence number range
    seq_numbers = list(unique_received.keys())
    min_seq = min(seq_numbers) if seq_numbers else 0
    max_seq = max(seq_numbers) if seq_numbers else 0

    # Print results
    print(f"\nANALYSIS RESULTS:")
    print("=" * 80)
    print(f"Time Analysis:")
    print(f"  First data packet:      {first_data_time:.6f} s")
    print(f"  Last data packet:       {last_data_time:.6f} s")
    print(f"  Transfer duration:      {duration:.6f} s")

    print(f"\nPacket Statistics:")
    print(f"  TCP data packets sent:     {tcp_data_sent}")
    print(f"  TCP data packets received: {tcp_data_received}")
    print(f"  ACK packets sent:          {ack_sent}")
    print(f"  Packet loss rate:          {loss_rate:.2f}%")
    print(f"  Sequence number range:     {min_seq} - {max_seq}")

    print(f"\nData Transfer:")
    print(f"  Payload per packet:     {payload_per_packet} bytes")
    print(f"  Total payload:          {total_payload_bytes:,} bytes")
    print(f"  Total payload bits:     {total_payload_bits:,} bits")

    print(f"\nThroughput:")
    print(f"  Effective throughput:   {throughput_bps:,.2f} bps")
    print(f"  Effective throughput:   {throughput_kbps:,.2f} kbps")
    print(f"  Effective throughput:   {throughput_mbps:.3f} Mbps")

    print(f"\nLink Capacity Comparison:")
    print(f"  Link bandwidth:         1,000,000 bps (1 Mbps)")
    print(f"  Utilization:            {(throughput_bps / 1000000) * 100:.2f}%")

    return {
        'throughput_bps': throughput_bps,
        'throughput_kbps': throughput_kbps,
        'throughput_mbps': throughput_mbps,
        'duration': duration,
        'data_packets': num_data_packets,
        'total_payload_bytes': total_payload_bytes,
        'loss_rate': loss_rate
    }


def show_packet_samples(filename, num_samples=15):
    """Show first few packets to understand the pattern"""
    print(f"\nFIRST {num_samples} PACKETS:")
    print("=" * 80)

    if not os.path.exists(filename):
        return

    sample_count = 0
    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            if line.startswith(('+', '-', 'h', 'r')):
                parts = line.split()
                if len(parts) >= 15:
                    event = parts[0]
                    time = parts[2]
                    src = parts[4]
                    dst = parts[6]
                    pkt_type = parts[8]
                    size = parts[10]
                    seq = parts[14]

                    print(f"{event:1} t={time:8} {src:>2}→{dst:<2} "
                          f"type={pkt_type:4} size={size:4} seq={seq:4}")

                    sample_count += 1
                    if sample_count >= num_samples:
                        break


def main():
    if len(sys.argv) != 2:
        print("Usage: python trace_analyzer.py <trace_file>")
        print("Example: python trace_analyzer.py output.tr")
        sys.exit(1)

    filename = sys.argv[1]

    # Show packet samples first
    show_packet_samples(filename)

    # Run full analysis
    print("\n" + "=" * 80)
    results = analyze_trace_file(filename)

    if results:
        print(f"\nAnalysis completed successfully!")
    else:
        print(f"\nAnalysis failed!")


if __name__ == "__main__":
    main()
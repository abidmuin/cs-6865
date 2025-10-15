#!/usr/bin/env python3
"""
NS2 Trace File Analyzer
"""

import re
import sys
from typing import Dict


class NS2TraceAnalyzer:
    def __init__(self, trace_file_path: str):
        self.trace_file_path = trace_file_path
        self.packets = []

    def parse_trace_file(self) -> Dict:
        """Parse the NS2 trace file with regex patterns"""
        send_pattern = r'^\+\s+-t\s+([\d.eE+-]+).*?-i\s+(\d+).*?-e\s+(\d+)'
        receive_pattern = r'^r\s+-t\s+([\d.eE+-]+).*?-i\s+(\d+)'

        def parse_event_line(line: str) -> Dict:
            """Parse individual event line by extracting key-value pairs"""
            fields = {}

            # Extract event type
            event_match = re.match(r'^([+\-rh])\s+', line)
            if not event_match:
                return None

            fields['type'] = event_match.group(1)

            # Extract key-value pairs
            kv_pattern = r'-(\w+)\s+([^\s-]+)'
            matches = re.findall(kv_pattern, line)

            for key, value in matches:
                # Convert numeric values
                if key in ['t', 'e', 'i', 's', 'd', 'c', 'a']:
                    try:
                        fields[key] = float(value) if '.' in value else int(value)
                    except ValueError:
                        fields[key] = value
                else:
                    fields[key] = value

            return fields

        send_events = []
        receive_events = []
        first_time = None
        last_time = None
        line_count = 0

        try:
            with open(self.trace_file_path, 'r') as file:
                for line_num, line in enumerate(file, 1):
                    line = line.strip()
                    line_count += 1

                    # Skip empty lines and comments
                    if not line or line.startswith('#'):
                        continue

                    # Parse using flexible field-based approach
                    parsed = parse_event_line(line)
                    if not parsed:
                        continue

                    # Handle send events
                    if parsed.get('type') == '+' and 't' in parsed and 'i' in parsed and 'e' in parsed:
                        send_events.append({'time': parsed['t'], 'id': parsed['i'], 'size': parsed['e'], 'type': 'send',
                                            'line': line_num, 'raw_line': line})

                        if first_time is None:
                            first_time = parsed['t']
                        last_time = parsed['t']

                    # Handle receive events
                    elif parsed.get('type') == 'r' and 't' in parsed and 'i' in parsed:
                        receive_events.append(
                            {'time': parsed['t'], 'id': parsed['i'], 'type': 'receive', 'line': line_num,
                             'raw_line': line})

            print(f"Parsing complete: {len(send_events)} send events, {len(receive_events)} receive events")

            return {'send_events': send_events, 'receive_events': receive_events, 'first_time': first_time,
                    'last_time': last_time, 'total_lines': line_count}

        except Exception as e:
            print(f"Error parsing trace file: {e}")
            import traceback
            traceback.print_exc()
            return None

    def validate_parsing(self, analysis_data: Dict) -> bool:
        """Validate that parsing captured the expected data"""
        if not analysis_data:
            return False

        send_events = analysis_data['send_events']
        if not send_events:
            print("ERROR: No send events found!")
            return False

        # Check first few events to verify parsing
        print("\nVALIDATING PARSED DATA:")
        print("-" * 50)

        for i, event in enumerate(send_events[:3]):
            print(f"Send Event {i}: time={event['time']}, id={event['id']}, size={event['size']}")
            print(f"  Raw: {event['raw_line']}")

        if len(send_events) > 3:
            print("...")
            for event in send_events[-2:]:
                print(f"Send Event ...: time={event['time']}, id={event['id']}, size={event['size']}")

        return True

    def calculate_throughput(self, analysis_data: Dict) -> Dict:
        """Calculate throughput metrics from parsed data"""

        if not analysis_data or not analysis_data['send_events']:
            return None

        send_events = analysis_data['send_events']
        receive_events = analysis_data['receive_events']
        first_time = analysis_data['first_time']
        last_time = analysis_data['last_time']

        print(f"\nCALCULATION INPUTS:")
        print(f"First packet time: {first_time}")
        print(f"Last packet time:  {last_time}")
        print(f"Send events count: {len(send_events)}")
        print(f"Receive events count: {len(receive_events)}")

        # Calculate based on sent packets
        total_duration = last_time - first_time
        total_packets_sent = len(send_events)

        # Get packet size from first event
        packet_size = send_events[0]['size'] if send_events else 0

        # Calculate total bytes and bits
        total_bytes_sent = total_packets_sent * packet_size
        total_bits_sent = total_bytes_sent * 8

        # Calculate throughput
        sent_throughput_bps = total_bits_sent / total_duration if total_duration > 0 else 0

        # For received throughput
        total_bytes_received = len(receive_events) * packet_size
        total_bits_received = total_bytes_received * 8
        received_throughput_bps = total_bits_received / total_duration if total_duration > 0 else 0

        # Packet delivery ratio
        delivery_ratio = len(receive_events) / total_packets_sent if total_packets_sent > 0 else 0

        return {'time_duration_seconds': total_duration, 'total_packets_sent': total_packets_sent,
                'total_packets_received': len(receive_events), 'packet_size_bytes': packet_size,
                'total_bytes_sent': total_bytes_sent, 'total_bytes_received': total_bytes_received,
                'total_bits_sent': total_bits_sent, 'total_bits_received': total_bits_received,
                'sent_throughput_bps': sent_throughput_bps, 'sent_throughput_kbps': sent_throughput_bps / 1000,
                'sent_throughput_mbps': sent_throughput_bps / 1000000,
                'received_throughput_bps': received_throughput_bps,
                'received_throughput_kbps': received_throughput_bps / 1000,
                'received_throughput_mbps': received_throughput_bps / 1000000, 'packet_delivery_ratio': delivery_ratio,
                'first_packet_time': first_time, 'last_packet_time': last_time}

    def generate_report(self, throughput_data: Dict, analysis_data: Dict) -> str:
        """Generate a comprehensive analysis report"""

        report = []
        report.append("=" * 70)
        report.append("NS2 TRACE FILE ANALYSIS REPORT")
        report.append("=" * 70)
        report.append(f"Trace file: {self.trace_file_path}")
        report.append(f"Total lines processed: {analysis_data['total_lines']:,}")
        report.append("")

        # Time information
        report.append("TIME ANALYSIS:")
        report.append("-" * 40)
        report.append(f"First packet sent at: {throughput_data['first_packet_time']:.6f} seconds")
        report.append(f"Last packet sent at:  {throughput_data['last_packet_time']:.6f} seconds")
        report.append(f"Total duration:       {throughput_data['time_duration_seconds']:.6f} seconds")
        report.append("")

        # Packet statistics
        report.append("PACKET STATISTICS:")
        report.append("-" * 40)
        report.append(f"Total packets sent:     {throughput_data['total_packets_sent']:,}")
        report.append(f"Total packets received: {throughput_data['total_packets_received']:,}")
        report.append(f"Packet size:           {throughput_data['packet_size_bytes']} bytes")
        report.append(f"Packet delivery ratio: {throughput_data['packet_delivery_ratio']:.2%}")
        report.append("")

        # Throughput statistics
        report.append("THROUGHPUT ANALYSIS:")
        report.append("-" * 40)
        report.append("SENT THROUGHPUT (Offered Load):")
        report.append(f"  {throughput_data['sent_throughput_bps']:,.2f} bps")
        report.append(f"  {throughput_data['sent_throughput_kbps']:,.2f} kbps")
        report.append(f"  {throughput_data['sent_throughput_mbps']:.3f} Mbps")
        report.append("")
        report.append("RECEIVED THROUGHPUT (Effective Throughput):")
        report.append(f"  {throughput_data['received_throughput_bps']:,.2f} bps")
        report.append(f"  {throughput_data['received_throughput_kbps']:,.2f} kbps")
        report.append(f"  {throughput_data['received_throughput_mbps']:.3f} Mbps")
        report.append("")

        # Sample verification
        report.append("VERIFICATION SAMPLES:")
        report.append("-" * 40)
        report.append("First 2 send events:")
        for i, event in enumerate(analysis_data['send_events'][:2]):
            report.append(f"  Line {event['line']}: + -t {event['time']} -i {event['id']} -e {event['size']}")

        if len(analysis_data['send_events']) > 2:
            report.append("Last send event:")
            last_event = analysis_data['send_events'][-1]
            report.append(
                f"  Line {last_event['line']}: + -t {last_event['time']} -i {last_event['id']} -e {last_event['size']}")

        report.append("=" * 70)

        return "\n".join(report)

    def analyze(self) -> Dict:
        """Main analysis function"""

        print("Analyzing NS2 trace file...")

        # Parse the trace file
        analysis_data = self.parse_trace_file()
        if not analysis_data:
            return None

        # Validate parsing
        if not self.validate_parsing(analysis_data):
            return None

        # Calculate throughput metrics
        throughput_data = self.calculate_throughput(analysis_data)
        if not throughput_data:
            return None

        # Generate and print report
        report = self.generate_report(throughput_data, analysis_data)
        print("\n" + report)

        return {'analysis_data': analysis_data, 'throughput_data': throughput_data, 'report': report}


def main():
    """Main function to run the analyzer"""

    if len(sys.argv) != 2:
        print("Usage: python ns2_analyzer.py <trace_file.nam>")
        sys.exit(1)

    trace_file = sys.argv[1]

    # Create analyzer and run analysis
    analyzer = NS2TraceAnalyzer(trace_file)
    results = analyzer.analyze()

    if results:
        print("\nAnalysis completed successfully!")

        # Save report to file
        output_file = f"{trace_file}_analysis.txt"
        with open(output_file, 'w') as f:
            f.write(results['report'])
        print(f"Detailed report saved to: {output_file}")
    else:
        print("Analysis failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()

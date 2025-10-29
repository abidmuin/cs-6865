#!/bin/bash
# Exercise 3 Drop Analysis Script
# Usage: bash analyze-3.sh

echo "========================================"
echo "EXERCISE 3: TCP vs CBR - DROP ANALYSIS"
echo "========================================"
echo ""

# Total drops
total_drops=$(grep "^d" out.tr | wc -l)
echo "Total dropped packets: $total_drops"
echo ""

# Packets received at destinations
echo "=== Packets RECEIVED at destinations ==="
tcp_received=$(grep "^r" out.tr | grep " 4 " | wc -l)
cbr_received=$(grep "^r" out.tr | grep " 5 " | wc -l)
echo "TCP Flow (to node 4): $tcp_received packets"
echo "CBR Flow (to node 5): $cbr_received packets"
echo ""

# Drops by destination
echo "=== Packets DROPPED by destination ==="
tcp_drops=$(grep "^d" out.tr | grep "4.0" | wc -l)
cbr_drops=$(grep "^d" out.tr | grep "5.0" | wc -l)

echo "TCP Flow (dest 4.0): $tcp_drops drops"
echo "CBR Flow (dest 5.0): $cbr_drops drops"

if [ $total_drops -gt 0 ]; then
    tcp_pct=$(awk "BEGIN {printf \"%.1f\", ($tcp_drops * 100.0 / $total_drops)}")
    cbr_pct=$(awk "BEGIN {printf \"%.1f\", ($cbr_drops * 100.0 / $total_drops)}")
    echo ""
    echo "Drop distribution:"
    echo "  TCP: $tcp_pct%"
    echo "  CBR: $cbr_pct%"
fi
echo ""

# Drop timing analysis
echo "=== Drop timing analysis ==="
grep "^d" out.tr | awk '{print $2}' | awk '
{
    if ($1 < 5) before++;
    else if ($1 <= 15) during++;
    else after++;
}
END {
    print "Before overlap (<5s):", before+0;
    print "During overlap (5-15s):", during+0;
    print "After overlap (>15s):", after+0;
}'
echo ""

# First 10 drops
# echo "=== First 10 dropped packets ==="
# grep "^d" out.tr | head -10 | awk '{printf "Time: %6.3f  From: %s->%s  Dest: %s  Type: %s\n", $2, $3, $4, $10, $5}'
# echo ""

# Summary
echo "========================================"
echo "SUMMARY"
echo "========================================"
echo "TCP Flow: $tcp_received received, $tcp_drops dropped"
echo "CBR Flow: $cbr_received received, $cbr_drops dropped"
echo ""

if [ $tcp_drops -gt $cbr_drops ]; then
    echo "OBSERVATION: TCP dropped MORE packets than CBR"
    echo "This demonstrates TCP's congestion control causing it"
    echo "to back off while aggressive UDP maintains its rate."
else
    echo "OBSERVATION: Drop distribution is different from expected"
fi

echo "========================================"
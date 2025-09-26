# Calculations
import os

# Visualization
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

Pt = 0.1  # W
B = 22e6  # Hz
f = 2.4e9  # Hz
T = 400  # K
k = 1.38e-23  # J/K
c = 3e8  # m/s
pi = 3.14

N = k * T * B
print(f"Noise power N = k * T * B = {N:.2e} W\n")

# Distances from 10 m to 100 m in steps of 10 m
distances = list(range(10, 101, 10))

rows = []
capacities = []
for d in distances:
    L = (4 * pi * f * d / c) ** 2
    S = Pt / L
    SNR = S / N
    C = (B * np.log2(1 + SNR))
    # rows.append({"d (m)": d, "L (linear)": f"{L:0.2e}", "S (W)": f"{S:0.2e}", "S/N (linear)": f"{SNR:0.2e}",
    #              "C (bps)": f"{C:0.2e}"})
    rows.append({"d (m)": d, "L (linear)": f"{L:0.2e}", "S (W)": f"{S:0.2e}",
                 "C (Mbps)": f"{C:0.2e}"})
    capacities.append(C)

capacities_mbps = np.array(capacities) / 1e6

df = pd.DataFrame(rows)
df_display = df.copy()
print(df_display.to_string(index=False))

cwd = os.getcwd()
df.to_csv(cwd + "/results.csv", index=False)
print("A CSV of the numeric results was saved to " + cwd)

# Plot
plt.figure(figsize=(8, 6))
plt.plot(distances, capacities_mbps, marker='o')
plt.title("Maximum Data Rate (Theoretical) vs Distance (802.11b)")
plt.xlabel("Distance (m)")
plt.ylabel("Capacity (Mbps)")
plt.xticks(np.arange(10, 101, 10))
plt.grid(True)
plt.savefig("graph.png", dpi=300, bbox_inches='tight')
plt.show()

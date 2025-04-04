# Monitoring-System-Resources-for-a-Proxy-Server

This Bash script is designed to monitor system resources for a **SafeSquid proxy server**. It provides real-time data on CPU, memory, disk usage, network activity, and essential services.

## Features:
✅ Top 10 CPU & Memory-consuming applications  
✅ Active network connections and packet drops  
✅ Disk usage with alerts for high consumption  
✅ System load, memory, and swap usage  
✅ Active process monitoring  
✅ Essential services like `sshd`, `iptables`, and `nginx`  

## Prerequisites
Ensure you have the following installed on the SafeSquid machine:
- **Bash** (default on Linux)
- `top`, `ps`, `free`, `df`, `ss`, `iptables`, `awk`

## Installation & Usage
### **1️⃣ Download the Script**
On your **SafeSquid machine**, run:
```bash
git clone https://github.com/your-username/repository-name.git
cd repository-name

# Monitoring-System-Resources-for-a-Proxy-Server

## 📌 Overview
This **Bash script** monitors system resources on a **SafeSquid proxy server**, providing real-time insights into:
- **CPU & Memory Usage**
- **Active Network Connections**
- **Disk Usage & Alerts**
- **System Load**
- **Running Processes**
- **Essential Services (nginx, sshd, iptables, etc.)**

## ⚡ Installation
1. **Clone this repository** on your **SafeSquid machine**:
   ```bash
   git clone https://github.com/Nachiketvc/Monitoring-System-Resources-for-a-Proxy-Server.git
   cd Monitoring-System-Resources-for-a-Proxy-Server

2. **Give Execution Permission to the script:**
   ```bash
   chmod +x script.sh

3. **Run the script**
   ```bash
   chmod +x script.sh

4. 🖥️ System Monitoring Dashboard

This system provides real-time monitoring with **test cases numbered from 1 to 7**. When a user inputs any of these numbers, the corresponding output is displayed, refreshing every **100 seconds** to ensure updated information.

## 📌 Features

Each test case (1 to 7) corresponds to a specific function:
- 🔹 **Listing the top 10 most used applications**
- 🔹 **Monitoring disk usage**
- 🔹 **Tracking active processes**
- 🔹 **Checking service status**

Additionally, **Test Case 8** consolidates all information and displays it in one go. Like the others, this output also refreshes every **100 seconds** to maintain accuracy.

## ⚡ Command-Line Switches

To enhance usability, command-line switches allow users to view specific sections of the dashboard:
```sh
-cpu      # View CPU usage details
-memory   # Check memory utilization
-network  # Monitor network activity

   

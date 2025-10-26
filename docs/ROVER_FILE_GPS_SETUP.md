# 🚀 File-Based GPS System Setup

The app now uses a **file-based GPS polling system** instead of TCP sockets for better reliability!

## 📋 How It Works

1. **Rover writes GPS data** to `gps.txt` file every second
2. **HTTP server serves** the `gps.txt` file
3. **Flutter app polls** the file every second via HTTP
4. **Much more reliable** than TCP socket streaming!

---

## 🛠️ Setup Instructions

### **Step 1: Update Your Rover Script**

Your rover script (`rover_dummy.py`) should write GPS data to `gps.txt`:

```python
import socket
import json
import time
import random

# TCP Server Configuration
HOST = '0.0.0.0'
PORT = 5555

def start_rover_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(1)

    print(f"🚀 Dummy GPS server listening on {HOST}:{PORT}")
    print("📡 Waiting for app connection...")

    while True:
        try:
            client_socket, client_address = server.accept()
            print(f"📱 App connected from {client_address}")

            lat = 12.9716
            lon = 77.5946

            while True:
                try:
                    # Simulate small movement
                    lat += random.uniform(-0.00005, 0.00005)
                    lon += random.uniform(-0.00005, 0.00005)

                    gps_data = {"lat": round(lat, 6), "lon": round(lon, 6)}
                    json_data = json.dumps(gps_data) + '\n'

                    # Send to app via TCP
                    client_socket.send(json_data.encode('utf-8'))

                    # ALSO write to file for HTTP polling
                    with open("gps.txt", "w") as f:
                        f.write(json_data)

                    print(f"📤 Sent & wrote GPS: {gps_data}")
                    time.sleep(1)

                except BrokenPipeError:
                    print("❌ App disconnected.")
                    break
                except Exception as e:
                    print(f"⚠️ Error: {e}")
                    time.sleep(1)

        except KeyboardInterrupt:
            print("\n🛑 Shutting down...")
            break
        except Exception as e:
            print(f"❌ Server error: {e}")
            time.sleep(3)
        finally:
            try:
                client_socket.close()
            except:
                pass

    server.close()

if __name__ == "__main__":
    start_rover_server()
```

### **Step 2: Start HTTP Server**

In a **separate terminal** on your Raspberry Pi, run:

```bash
python3 rover_http_server.py
```

You should see:
```
🌐 HTTP server started on port 8080
📁 Serving files from: /home/pi/rover
🔗 Access gps.txt at: http://172.20.10.4:8080/gps.txt
📱 Flutter app will poll this URL every second
```

### **Step 3: Test HTTP Access**

From your laptop (on the same network), test:

```bash
curl http://172.20.10.4:8080/gps.txt
```

You should see:
```json
{"lat": 12.971284, "lon": 77.594772}
```

---

## 📱 Using the App

### **1. Open Rover Connect Screen**

Navigate to: **Splash → Setup Clubs → Rover Connect**

### **2. Enter Rover IP**

- **IP Address:** `172.20.10.4` (your rover's IP)
- **Port:** Not needed for file polling!

### **3. Start GPS Polling**

Click the **"Start Polling"** button

You should see:
- 🟢 **Polling GPS file...**
- **Latitude:** 12.971284
- **Longitude:** 77.594772
- **Last update:** 0s ago
- ✅ **Ball detected!**

### **4. Watch Real-Time Updates**

The GPS coordinates will update **every second** automatically!

---

## 🔍 Troubleshooting

### **Problem: "No data" in app**

**Check 1:** Is the HTTP server running?
```bash
# On Raspberry Pi
ps aux | grep rover_http_server
```

**Check 2:** Can you access the file?
```bash
# From laptop
curl http://172.20.10.4:8080/gps.txt
```

**Check 3:** Is gps.txt being updated?
```bash
# On Raspberry Pi
watch -n 1 cat gps.txt
```

### **Problem: HTTP server not accessible**

**Fix 1:** Check firewall
```bash
# On Raspberry Pi
sudo ufw allow 8080
```

**Fix 2:** Verify rover is on correct network
```bash
# On Raspberry Pi
ip addr show wlan0
```

Should show: `172.20.10.4`

### **Problem: GPS coordinates not updating**

**Check:** Is the rover script writing to gps.txt?
```bash
# On Raspberry Pi
ls -lh gps.txt
# Should show recent timestamp
```

---

## 🎯 Advantages of File-Based System

### ✅ **More Reliable**
- No "Broken pipe" errors
- No socket connection issues
- Works across all platforms (iOS, Android, Web)

### ✅ **Easier to Debug**
- Just check the file: `cat gps.txt`
- Test with curl: `curl http://172.20.10.4:8080/gps.txt`
- View in browser: `http://172.20.10.4:8080/gps.txt`

### ✅ **Better Error Handling**
- HTTP timeouts are predictable
- Automatic retry on failure
- Clear error messages

### ✅ **Platform Independent**
- Works on iOS without special permissions
- No TCP socket limitations
- Standard HTTP protocol

---

## 📊 Expected Behavior

### **On Rover Console:**
```
📤 Sent & wrote GPS: {'lat': 12.971284, 'lon': 77.594772}
📤 Sent & wrote GPS: {'lat': 12.971994, 'lon': 77.594579}
📤 Sent & wrote GPS: {'lat': 12.971503, 'lon': 77.594783}
```

### **On HTTP Server Console:**
```
📡 Served gps.txt to 172.20.10.2
📡 Served gps.txt to 172.20.10.2
📡 Served gps.txt to 172.20.10.2
```

### **On App Screen:**
```
🟢 Polling GPS file...
📍 Lat: 12.971284, Lon: 77.594772
⏱️ Last update: 0s ago
✅ Ball detected!
```

---

## 🚀 Quick Start Commands

```bash
# Terminal 1: Start rover GPS script
python3 rover_dummy.py

# Terminal 2: Start HTTP server
python3 rover_http_server.py

# Terminal 3: Test access
curl http://172.20.10.4:8080/gps.txt

# Terminal 4: Run Flutter app
flutter run --debug
```

---

## 📝 Notes

- **Polling Interval:** 1 second (configurable in `file_gps_service.dart`)
- **HTTP Port:** 8080 (configurable in `rover_http_server.py`)
- **File Location:** Same directory as rover script
- **File Format:** Single line JSON: `{"lat": 12.971284, "lon": 77.594772}\n`

---

## 🎉 Success!

Once you see GPS coordinates updating in the app, you're all set! The file-based system is much more reliable than TCP sockets and easier to debug.

Happy golfing! ⛳️


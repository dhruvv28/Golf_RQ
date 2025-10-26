# 📁 Direct File Access Setup (No HTTP Needed!)

The app now reads `gps.txt` **directly from the rover** without needing an HTTP server!

---

## 🎯 **How It Works:**

1. **Rover writes GPS** to `gps.txt` every second
2. **App reads the file directly** via network share or TCP fallback
3. **Polls every 1 second** for fresh data
4. **No HTTP server needed!** ✅

---

## 🚀 **Quick Setup (Easiest Method - TCP Fallback):**

### **Step 1: Run Your Rover Script**

```bash
python3 rover_dummy.py
```

Your rover is already writing to `gps.txt` AND sending via TCP!

### **Step 2: Click "Start Polling" in App**

The app will:
1. Try to find `gps.txt` in common network locations
2. If file not found, **automatically use TCP** (port 5555)
3. Start receiving GPS data every second!

**That's it!** No additional setup needed. 🎉

---

## 📂 **Advanced: Network File Share (Optional)**

If you want the app to read the file directly (instead of TCP fallback), set up a network share:

### **On Raspberry Pi (Rover):**

#### **1. Install Samba:**
```bash
sudo apt-get update
sudo apt-get install samba samba-common-bin
```

#### **2. Create Share Directory:**
```bash
mkdir -p ~/rover_share
cd ~/rover_share
```

#### **3. Update Your Rover Script to Write Here:**
```python
# In rover_dummy.py, change:
with open("/home/pi/rover_share/gps.txt", "w") as f:
    f.write(json_data)
```

#### **4. Configure Samba:**
```bash
sudo nano /etc/samba/smb.conf
```

Add at the end:
```ini
[rover]
   path = /home/pi/rover_share
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
```

#### **5. Restart Samba:**
```bash
sudo systemctl restart smbd
```

### **On Your Phone/Laptop:**

#### **Android:**
- Install a file manager that supports SMB (like "Solid Explorer")
- Connect to: `smb://172.20.10.4/rover`
- The app will auto-detect the file

#### **iOS:**
- Go to Files app → Connect to Server
- Enter: `smb://172.20.10.4/rover`
- The app will auto-detect the file

#### **Windows:**
- Map network drive: `\\172.20.10.4\rover`
- The app will auto-detect the file

---

## 🎯 **Automatic Fallback System:**

The app tries multiple methods in order:

1. **Direct File Access** (if network share is set up)
   - `//172.20.10.4/share/gps.txt` (SMB)
   - `/mnt/rover/gps.txt` (Linux mount)
   - `/Volumes/rover/gps.txt` (macOS mount)
   - `gps.txt` (local file for testing)

2. **TCP Socket Fallback** (always works!)
   - Connects to `172.20.10.4:5555`
   - Reads GPS data directly from rover script
   - **This is what will work right now!** ✅

---

## 📊 **What You'll See:**

### **Console Output:**
```
[FileGpsService] ⚠️ GPS file not found at any path, trying TCP...
[FileGpsService] ✅ TCP GPS updated: lat=12.971606, lon=77.594516
[FileGpsService] ✅ TCP GPS updated: lat=12.971631, lon=77.594479
```

### **App Screen:**
```
🟢 Polling GPS file...
📍 Lat: 12.971606, Lon: 77.594516
⏱️ Last update: 0s ago
✅ Ball detected!
```

---

## ⚡ **Recommended: Just Use TCP Fallback!**

**You don't need to set up file sharing!** The TCP fallback works perfectly:

✅ **Simpler** - no network share setup needed  
✅ **Reliable** - direct connection to rover  
✅ **Fast** - polls every 1 second  
✅ **Works now** - no additional configuration  

Just run your rover script and click "Start Polling"! 🚀

---

## 🔍 **Troubleshooting:**

### **Problem: "No data" in app**

**Solution:** Make sure your rover script is running:
```bash
# Check if rover is running
ps aux | grep rover_dummy

# Check if port 5555 is open
netstat -an | grep 5555
```

### **Problem: GPS not updating**

**Solution:** Check rover is writing GPS data:
```bash
# On Raspberry Pi
cat gps.txt
# Should show latest GPS coordinates
```

---

## 🎉 **Success!**

Once you click "Start Polling", the app will automatically:
1. Try to find the GPS file
2. Fall back to TCP (which works right now!)
3. Start showing GPS coordinates every second

**No HTTP server needed!** 🎉


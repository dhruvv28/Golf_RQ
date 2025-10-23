// Simple feature flags & shared constants
enum CommsMode { ble, wifi, loopback }


class AppConfig {
static const CommsMode commsMode = CommsMode.wifi; // ble | wifi | loopback
static const bool useFakeRover = true; // simulator before hardware


// Wi‑Fi defaults (editable in settings UI later)
static const String defaultRoverIp = '192.168.4.1';
static const int defaultRoverPort = 5555;
}


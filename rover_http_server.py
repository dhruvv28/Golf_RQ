#!/usr/bin/env python3
"""
Simple HTTP server to serve gps.txt file to Flutter app
Run this alongside your GPS data generator script
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

class CORSRequestHandler(SimpleHTTPRequestHandler):
    """HTTP handler with CORS enabled for Flutter app"""
    
    def end_headers(self):
        # Enable CORS for all origins
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        # Custom logging
        if 'gps.txt' in args[0]:
            print(f"📡 Served gps.txt to {self.client_address[0]}")

def start_http_server(port=8080):
    """Start HTTP server on specified port"""
    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, CORSRequestHandler)
    
    print(f"🌐 HTTP server started on port {port}")
    print(f"📁 Serving files from: {os.getcwd()}")
    print(f"🔗 Access gps.txt at: http://172.20.10.4:{port}/gps.txt")
    print(f"📱 Flutter app will poll this URL every second")
    print("\nPress Ctrl+C to stop\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Shutting down HTTP server...")
        httpd.shutdown()

if __name__ == "__main__":
    start_http_server(8080)


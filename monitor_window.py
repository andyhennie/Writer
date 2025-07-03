#!/usr/bin/env python3
"""
Monitor Writer app window dimensions and position.
Run this while testing the hide/show functionality.
"""

import subprocess
import time
import json

def get_window_info():
    """Get window info for Writer app using simpler approach."""
    try:
        # Try to get window bounds for Writer app
        result = subprocess.run([
            'osascript', '-e', 
            'tell application "System Events" to tell process "Writer" to get bounds of window 1'
        ], capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            output = result.stdout.strip()
            if not output or output == "":
                return None
            
            # Parse bounds: {x1, y1, x2, y2}
            bounds = output.replace('{', '').replace('}', '').split(',')
            if len(bounds) == 4:
                x1, y1, x2, y2 = map(int, [b.strip() for b in bounds])
                return {
                    'x': x1, 
                    'y': y1, 
                    'width': x2 - x1, 
                    'height': y2 - y1
                }
    except Exception as e:
        # Silently skip errors when app isn't running
        pass
    
    return None

def monitor_window():
    """Continuously monitor window changes."""
    print("Monitoring Writer app window... Press Ctrl+C to stop")
    print("Format: [timestamp] x=X y=Y w=WIDTH h=HEIGHT (changes)")
    print("-" * 60)
    
    last_info = None
    
    try:
        while True:
            current_info = get_window_info()
            
            if current_info:
                timestamp = time.strftime("%H:%M:%S")
                
                if last_info != current_info:
                    changes = []
                    if last_info:
                        if current_info['x'] != last_info['x']:
                            changes.append(f"x{current_info['x'] - last_info['x']:+d}")
                        if current_info['y'] != last_info['y']:
                            changes.append(f"y{current_info['y'] - last_info['y']:+d}")
                        if current_info['width'] != last_info['width']:
                            changes.append(f"w{current_info['width'] - last_info['width']:+d}")
                        if current_info['height'] != last_info['height']:
                            changes.append(f"h{current_info['height'] - last_info['height']:+d}")
                    
                    change_str = f" ({', '.join(changes)})" if changes else " (initial)"
                    
                    print(f"[{timestamp}] x={current_info['x']} y={current_info['y']} "
                          f"w={current_info['width']} h={current_info['height']}{change_str}")
                    
                    last_info = current_info
            
            time.sleep(0.1)  # Check every 100ms
            
    except KeyboardInterrupt:
        print("\nMonitoring stopped.")

if __name__ == "__main__":
    monitor_window()
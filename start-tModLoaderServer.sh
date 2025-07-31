#!/usr/bin/env bash

# Detect public IPv4 address using common services (requires curl)
get_public_ip() {
    if command -v curl >/dev/null 2>&1; then
        # Try multiple services in case one fails
        local ip
        for service in "https://api.ipify.org" "https://ipinfo.io/ip" "https://ifconfig.me"; do
            ip=$(curl -s --max-time 5 "$service")
            if [[ $? -eq 0 && -n "$ip" ]]; then
                echo "$ip"
                return
            fi
        done
    fi
    echo "Unavailable"
}

# Attempt to automatically open the firewall for the Terraria port
open_firewall_port() {
    local port="$1"

    # If ufw is available, use it
    if command -v ufw >/dev/null 2>&1; then
        if sudo ufw status >/dev/null 2>&1; then
            echo "Attempting to open TCP port $port via ufw..."
            sudo ufw allow "$port/tcp" || echo "Warning: ufw command failed or permission denied."
        fi
        return
    fi

    # Fall back to iptables if present
    if command -v iptables >/dev/null 2>&1; then
        echo "Attempting to open TCP port $port via iptables..."
        sudo iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || \
        sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT || \
        echo "Warning: iptables command failed or permission denied."
    fi
}

# =============================================================
# Main script starts here

cd "$(dirname "$0")" ||
{ read -n 1 -s -r -p "Can't cd to script directory. Press any button to exit..." && exit 1; }

# Use fixed Terraria port (change here if you decide to run on another)
PORT=7777

# Try to open the firewall port (requires sudo privileges)
open_firewall_port "$PORT"

# Get public IP for player connection info
PUBLIC_IP="$(get_public_ip)"

if [[ "$PUBLIC_IP" != "Unavailable" ]]; then
    echo "============================================="
    echo "Terraria server will be accessible at:"
    echo "  ${PUBLIC_IP}:${PORT}"
    echo "============================================="
else
    echo "Warning: Unable to determine public IP automatically."
fi

launch_args="-server"

# Always disable Steam
launch_args="$launch_args -nosteam"

# Always use serverconfig.txt
launch_args="$launch_args -config serverconfig.txt"
# Force tModLoader save directory to this server folder
launch_args="$launch_args -tmlsavedirectory ./"

# Pass through any additional arguments (except -steam, -nosteam, -config)
for arg in "$@"; do
	case $arg in
		-steam|-nosteam|-config)
			# Skip these arguments
			;;
		*)
			launch_args="$launch_args $arg"
			;;
	esac
done

chmod +x ./LaunchUtils/ScriptCaller.sh

# Start the automated backup script in the background.
# The & at the end of the line is what makes it run in the background.
./backup-world.sh &

./LaunchUtils/ScriptCaller.sh $launch_args

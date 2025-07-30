#!/usr/bin/env bash
cd "$(dirname "$0")" ||
{ read -n 1 -s -r -p "Can't cd to script directory. Press any button to exit..." && exit 1; }

launch_args="-server"

# Always disable Steam
launch_args="$launch_args -nosteam"

# Always use serverconfig.txt
launch_args="$launch_args -config serverconfig.txt"

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
./LaunchUtils/ScriptCaller.sh $launch_args

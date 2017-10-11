#!/bin/sh

if [ "$1" == "start" ]; then
   sudo launchctl load -F /Library/LaunchDaemons/com.diebold.warsaw.plist
        launchctl load -F /Library/LaunchAgents/com.diebold.warsaw.user.plist
elif [ "$1" == "stop" ]; then
        launchctl unload -w /Library/LaunchAgents/com.diebold.warsaw.user.plist
   sudo launchctl unload -w /Library/LaunchDaemons/com.diebold.warsaw.plist
fi

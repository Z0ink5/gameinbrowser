#!/bin/bash

# Start KasmServer (modify the command as needed)
vncserver &

# Start Steam (modify the command as needed)
su - steamuser -c "steam"

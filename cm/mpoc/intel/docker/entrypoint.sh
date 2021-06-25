#!/bin/bash
# exit immediately if a command exits with a non-zero status.
set -e

# Create default local username (docker)
# If LOCAL_USER_ID, LOCAL_GROUP_ID and LOCAL_USER are not passed in at runtime
# then use the default username, UID and GID
UID=${LOCAL_USER_ID:-1000}
GID=${LOCAL_GROUP_ID:-1000}
USER=${LOCAL_USER:-docker}

# Create docker group with the GID
groupadd -g $GID docker

# If user home directory exists
if [ -d "/home/$USER" ]; then
    # Create user account with the provided username, UID and GID
    # but without creating home directory
    useradd -s /bin/bash -M -u $UID -g $GID $USER
# If user home directory does not exist
else
    # Create user account with the provided username, UID, GID and
    # create home directory
    useradd -s /bin/bash -m -u $UID -g $GID $USER
fi

# Grant user with sudo privilege
echo "$USER            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

# Display username, UID, GID and working directory for user awareness
echo "Starting with USER: $USER, UID: $UID, GID: $GID"

# Execute the input command with the given non-privileged user
exec /usr/local/bin/gosu $USER "$@"
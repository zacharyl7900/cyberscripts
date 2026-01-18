#!/bin/bash

echo "Administrators:"

# List admins (sudo group)
getent group sudo | cut -d: -f4 | tr ',' '\n' | sed '/^$/d'

echo
echo "Standard Users:"

# List standard users (UID >= 1000, not in sudo)
awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | grep -v -f <(
    getent group sudo | cut -d: -f4 | tr ',' '\n'
)

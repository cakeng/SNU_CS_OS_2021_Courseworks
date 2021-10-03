# if DBUS session address is not set, try to set it, by getting the DBUS_SESSIONS_BUS_ADDRESS variable
# from the first systemd process running for the current user.
# This typically allows a 'su - <user>' command to have the right DBUS address.

# pgrep doesn't work at tizen 4.0. Replace with the following code.
# if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
#    systemd_pid=$(pgrep -U $UID systemd | head -1)
#    if [[ -n "$systemd_pid" ]]; then
#       val=$(tr '\0' '\n' < /proc/${systemd_pid}/environ | sed  '/^DBUS_SESSION_BUS_ADDRESS=/!d ; s/[^=]*=//')
#       [[ -n "$val" ]] && export DBUS_SESSION_BUS_ADDRESS=$val
#    fi
# fi


# The adbd's privilege has been changed form "System::Privileged" to "User::Shell".
# So, pgrep does not work with smack errors when accessing /proc.
# If it fails to find DBUS address, the fixed address is used.

if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
   [[ "$UID" != "0" ]] && export DBUS_SESSION_BUS_ADDRESS="kernel:path=/sys/fs/kdbus/${UID}-user/bus;unix:path=/run/user/${UID}/bus"
fi


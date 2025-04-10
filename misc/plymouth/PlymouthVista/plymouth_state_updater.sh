#!/bin/bash

if [[ $1 != "desktop" ]] && [[ $1 != "sddm" ]]; then
    echo Supply either "desktop" or "sddm"
    exit 2
fi

if [[ $2 == "--no-shutdown" ]] && [[ "`systemctl is-system-running`" == "running" ]]; then
    echo "No shutdown is pending"
    exit 0
fi

sed -i '/# START_USED_BY_SERVICE/,/# END_USED_BY_SERVICE/{ 
    /# START_USED_BY_SERVICE/!{ 
        /# END_USED_BY_SERVICE/!d 
    } 
    r /dev/stdin
}' /usr/share/plymouth/themes/PlymouthVista/PlymouthVista.script <<EOF
global.OsState = "$1";
EOF

echo "Updated status to $1"
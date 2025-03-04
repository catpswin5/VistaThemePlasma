# IMPORTANT: This install script has only been tested on Arch Linux.
# Installation procedure may vary from distribution-to-distribution.

if [[ "$EUID" != 0 ]]
then
    echo "You need to run this script as root."
    exit 2
fi


cp ./lucon_disable_anti_aliasing.conf /etc/fonts/conf.d/10-lucon_disable_anti_aliasing.conf

rm -rf /usr/share/plymouth/themes/PlymouthVista
cp -r $(pwd) /usr/share/plymouth/themes/PlymouthVista
plymouth-set-default-theme -R PlymouthVista

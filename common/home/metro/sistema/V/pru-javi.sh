#!/bin/sh
cd /home/metro/sistema/V

# Actualizacion local de los ficheros de configuracion
if grep pci /etc/hosts 2>/dev/null >/dev/null ; then
        /usr/sbin/ping pci 2 2>/dev/null >/dev/null
        if [ $? = 0 ]
        then
                echo "Actualizando PCI"
                ./pci-ftp.sh 2>/dev/null >/dev/null
        else
                echo "PCI Sin Comunicacion"
        fi
else
        echo "No hay PCI en la estacion"
fi


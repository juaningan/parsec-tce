#!/bin/sh

numargs=$#
nombreprog=$0

if [ $numargs = "0" ]; then
	UsaXpm=no
elif [ $numargs = "1" ]; then
	if [ $1 = "xpm" ]; then
		UsaXpm=si
	else
		echo "$nombreprog: Argumento incorrecto"	
		echo "Sintaxis: $nombreprog [xpm]"
		exit 1
	fi
else
	echo "$nombreprog: Argumentos incorrectos"     
        echo "Sintaxis: $nombreprog [xpm]"
        exit 1
fi

cd /home/metro/sistema/V
./pru-javi.sh
if [ $UsaXpm = "si" ]; then
	echo "Actualizando el Puesto Central con XPM's"
else
	echo "Actualizando el Puesto Central"
fi
loc=`cat CfgEquipo.CFG | grep PPT | sed "s/^[^0-9]*//g" | sed "s/^\(....\).*/\1/g" | head -1`
if grep main2 /etc/hosts 2>/dev/null >/dev/null ; then 
if [ $loc"m" = "m" ]; then
	loc=`cat CfgEquipo.CFG | grep PCL | sed "s/^[^0-9]*//g" | sed "s/^\(....\).*/\1/g" | head -1`
	if [ $loc"m" = "m" ]; then
		loc=`cat CfgEquipo.CFG | grep CAN | sed "s/^[^0-9]*//g" | sed "s/^\(....\).*/\1/g" | head -1`
		if [ $loc"m" = "m" ]; then
			echo "Imposible obtener localizacion de la estacion"
			exit 1
		fi
	fi
fi
	echo nada > /dev/null
else
	distsh2 "echo 16.0.62.19  main2 >> /etc/hosts"
fi
if [ $UsaXpm = "si" ]; then
	rcp *xpm main2:/mnt/captura/metro/sistema/V/Comun
	rcp *xpm main2:/u02/captura/metro/sistema/V/Comun
fi
rcp *icons main2:/mnt/captura/metro/sistema/V/Comun/${loc}1.icons
rcp *icons main2:/u02/captura/metro/sistema/V/Comun/${loc}1.icons
rcp *Raster main2:/mnt/captura/metro/sistema/V/Comun/${loc}1.Raster
rcp *Raster main2:/u02/captura/metro/sistema/V/Comun/${loc}1.Raster
FichTextos=`ls -1 FichTextos* | grep -v FichTextosEstacion | tr -d "@*"`
echo $FichTextos
rcp $FichTextos main2:/mnt/captura/metro/sistema/V/Comun/${loc}1.Textos
rcp $FichTextos main2:/u02/captura/metro/sistema/V/Comun/${loc}1.Textos
grep POZO *.icons >/dev/null
if [ $? = "0" ]; then
	echo "Actualizando Pozos en Puesto Central"
	cd /home/metro/sistema/V/Pozos
	rcp ${loc}.CFG main2:/mnt/captura/metro/sistema/V/Comun/Pozos/${loc}.CFG
	rcp ${loc}.CFG main2:/u02/captura/metro/sistema/V/Comun/Pozos/${loc}.CFG
	cd /home/metro/sistema/V
fi
grep ASCENSOR *.icons >/dev/null
if [ $? = "0" ]; then
	echo "Actualizando Niveles de Ascensores en Puesto Central"
	cd /home/metro/sistema/V/Ascensor
	rcp Niveles.CFG main2:/mnt/captura/metro/sistema/V/Comun/Ascensor/${loc}.CFG
	rcp Niveles.CFG main2:/u02/captura/metro/sistema/V/Comun/Ascensor/${loc}.CFG
	cd /home/metro/sistema/V
fi
/home/metro/sun/anti_intrusion_config

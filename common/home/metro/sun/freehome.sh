#!/bin/sh
#
# /home/metro/sun/freehome.sh: En caso de que se llene /home en más de un 90%
#                            hace sitio borrando ficheros no necesarios. Si sigue estando
#                            lleno hace más sitio borrando ficheros más delicados y rebota.
#                            Pensado para ser llamado desde el crontab de metro una vez
#                            por hora. Versión para estaciones y vestíbulos.
#
# Uso: 0 * * * * /home/metro/sun/freehome.sh
#
# Historia:
#
#        10-Dic-97 Alberto             Añadidos logs del SAI. Solo hace limpieza a fondo y
#                                      rebota cuando la partición está al 100% en lugar de
#                                      al 90%.
#        14-Nov-97 Alberto             Paso a nuevo método de documentación. Añadidos logs
#                                      de las cancelas.
#
# Por hacer:
#
# NOTAS:
#
#
homepercent=`/usr/sbin/df -k /home | /usr/bin/grep % | /usr/bin/awk '{print $5}' | /usr/bin/sed -e 's/%//g'`

if [ $homepercent -gt 90 ]; then
	echo "Home ocupado en mas de un 90%. Haciendo sitio..."
	cd /home/metro/sistema/V
	/usr/bin/rm -f *.Log.* 
	/usr/bin/rm -f Porton/*/*.Log.*
	/usr/bin/rm -f Cancela/*/xcan.*
	/usr/bin/rm -f Cancela/*/PuertoSerie.*
	/usr/bin/rm -f Newsai/*/xAnalogSAI.*
	/usr/bin/rm -f Newsai/*/xPuertoSAI.*

	homepercent=`/usr/sbin/df -k /home | /usr/bin/grep % | /usr/bin/awk '{print $5}' | /usr/bin/sed -e 's/%//g'`
	if [ $homepercent -eq 100 ]; then
		echo "Home sigue ocupado en un 100%. Rebotando..."
		(/usr/bin/sleep 15; /usr/bin/rm -f /home/metro/sistema/V/*.Log; /usr/bin/rm -f /home/metro/sistema/V/Porton/*/*.Log /home/metro/sistema/V/Cancela/*/xcan /home/metro/sistema/V/Cancela/*/PuertoSerie Newsai/*/xAnalogSAI Newsai/*/xPuertoSAI; /usr/bin/distsh2 '/usr/sbin/init 6') &
	else
		echo "OK."
	fi

fi

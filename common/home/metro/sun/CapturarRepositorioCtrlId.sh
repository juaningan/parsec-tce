#!/bin/sh
#ident  "Captura de datos particulares 1.0     21/7/2006"
#
# Copyright: SICOSOFT 2006
#
#
# CapturarRepositorioCtrlId.sh: Script que genera un fichero.tar que contiene solo los datos
#                     particulares de cada equipo de ControlId de la estación.
#
#
# Historia:
#            04-Sep-02 Carlos Culebras Alejo               Codigo inicial
#            14-Dic-04 Carlos Culebras Alejo               Directorio Repositorio
#                                                          y ejecutable por siv
#            21-Jul-06 Beatriz Fernandez Martinez          Modificacion de script para recoger otros datos
#
# Por hacer:
#
#
# NOTAS:
#
#
#
PATH=/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/ucb
export PATH

   set `id`
   if [ $1 != "uid=0(root)" ]; then
      echo "$0: Este script se debe ejecutar como Superusuario"
   fi

   Host=`/usr/bin/cat /etc/nodename | /usr/bin/awk '{print $1}' | sed "s/\(.*\)-\(.*\)/\1/g"`
   
   cd /home/metro/sistema/V
    host_temp=`awk ' (NF == 7 || NF == 5) && substr($4,1,5)=="front" { print $4 }' CfgConfig.CFG`
    host_remoto=`echo $host_temp | cut -f1 -d'@'`
    echo 'el nombre del front es '${host_remoto}

   # Nos colocamos en el directorio raiz y creamos el fichero con los
   # archivos que seran incluidos en el tar

   cd /home/metro/ControlId/Repositorio

   # Se hace un tar de los *tar.gz que ya han subido de los equipos de ControlId al TCE

   distsh2 "/usr/sbin/tar cf /home/metro/ControlId/Repositorio/$Host.tar t*" 

  # Se borra el anterior
  distsh2 "/usr/bin/rm /home/metro/ControlId/Repositorio/$Host.tar.gz"

  # Se comprime el tar
  /usr/local/bin/gzip /home/metro/ControlId/Repositorio/$Host.tar
  rcp /home/metro/ControlId/Repositorio/$Host.tar.gz $host_remoto:/home/metro/RepositorioCtrlId

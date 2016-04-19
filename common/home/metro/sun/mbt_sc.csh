#!/bin/csh -f

#if ( $#argv < 1 ) then
#       echo DISTRIBUCION_ERROR - Numero de argumentos insuficientes en ${0}.
#        exit (0)
#endif

set dir_mbt=$1	# Aqui nos pasan el directorio de la MBT a la que nos dirigimos 
		# de las que hay en este vestibulo (Ej. MBT00066)
set nom_mbt=$2  # Aqui nos pasan el nombre de la MBT a la que nos dirigimos 
		# de las que hay en este vestibulo (Ej. mbt o mbt1)
set fecha = `date`

echo "$fecha Ejecutando comandos..."

#grep -s -c $nom_mbt /etc/wsp.conf >&! /dev/null
#if ( $status == 0 ) then

  #echo "$fecha Hay MBT configurada"
  /usr/sbin/ping $nom_mbt >& /dev/null
  if ( $status == 1 ) then
    echo "$fecha - Sin COMUNICACION con $nom_mbt"
  else
    cd /home/metro/sistema/V/Mbt/$dir_mbt
        echo "$fecha - Pedir los volcados que aun no se hayan traido"
	set NumFichero = `echo $nom_mbt | awk '{ print substr($nom_mbt,7,1) }'`
	echo " - Es mbt_sc $NumFichero -"
	set Status = 2
	if ( $NumFichero == "" ) then
	        /home/metro/sun/ftp.expect -n < /home/metro/sistema/V/Mbt/mbt_sc_ftp.TRAER >> ../salida_sc.ftp
		set Status = $status
	else if ( $NumFichero == "1" ) then
	        /home/metro/sun/ftp.expect -n < /home/metro/sistema/V/Mbt/mbt_sc1_ftp.TRAER >> ../salida_sc.ftp
		set Status = $status
	else if ( $NumFichero == "2" ) then
	        /home/metro/sun/ftp.expect -n < /home/metro/sistema/V/Mbt/mbt_sc2_ftp.TRAER >> ../salida_sc.ftp
		set Status = $status
	endif

	echo " - Status resultante $Status"
        if ( $Status == 1 ) then
          echo "$fecha - No hay volcados"
          exit
        else
	 if ( $Status == 2 ) then
          echo "ERROR: Conexion fuera de tiempo"
          exit
	 else
          echo " - Buscar los data*zip que han llegado"
          #find . -name 'data*zip' -exec /usr/bin/unzip {} \;
          find . -name 'data*zip' -exec /home/metro/sun/TratarVolcado_SC.csh {} \;
	  
	  echo " - CreaVolcado para todos los volcados que han llegado hoy a $dir_mbt"
	  /home/metro/sun/CreaVolcado.ksh -p $dir_mbt /home/metro/sistema/V/Mbt/$dir_mbt

          echo " - Borro los volcados en la mbt_sc remota"
	  if ( $NumFichero == "" ) then
	  /usr/bin/ftp -n < /home/metro/sistema/V/Mbt/mbt_sc_ftp.BORRAR >> ../salida_sc.ftp
	  else if ( $NumFichero == "1" ) then
	  /usr/bin/ftp -n < /home/metro/sistema/V/Mbt/mbt_sc1_ftp.BORRAR >> ../salida_sc.ftp
	  else if ( $NumFichero == "2" ) then
	  /usr/bin/ftp -n < /home/metro/sistema/V/Mbt/mbt_sc2_ftp.BORRAR >> ../salida_sc.ftp
	  endif

          echo " - Borro los directorios de volcados aqui"
	  rm -r *
	 endif	  
        endif
  endif

#else
#   echo "$fecha - no hay MBT"
#endif

set fecha = `date`
echo "$fecha Todo bien en esta maquina."
exit


#!/bin/ksh -p
#!/bin/ksh -pv para que muestre linea a linea lo que va ejecutando.
#
# MandaVolcados.ksh: Manda los volcados.
#
# Uso: /home/metro/sun/MandaVolcados.ksh [-d] [-t] [-l <logfile>] [-v<directorio_volcados>]
#                   [-e <directorio_enviados>]
#
#      -d: activa depurado.
#      -t: Modo de prueba. El fichero CfgConfig.CFG que se lee es el dela variable
#          cfgfile_prueba en lugar de cfgfile_normal; el servidor dedatos puente es el de
#          hnservdat_prueba en lugar de hnservdat_normal (ver masabajo).
#      -l <logfile>: Selecciona un fichero de log distinto del pordefecto.
#                    El fichero debe tener path absoluto.
#      -v <directorio_volcados>: Selecciona un directorio de volcadosdistinto del de por
#                                defecto. Debe tener path absoluto.
#      -e <directorio_enviados>: Selecciona un directorio de enviadosdistinto del de por
#                                defecto, con path absoluto.
#
# Esta pensado para ser ejecutado periodicamente por el cron de 2 a 5
# de la ma±ana, es decir, la linea del crontab seria:
#
#      * 2-5 * * * /home/metro/sun/MandaVolcados.ksh
#
# para un periodo de un minuto (el maximo posible - no recomendable), y
#
#      0,15,30,45 2-5 * * * /home/metro/sun/MandaVolcados.ksh
#
# para un periodo de quince minutos.
#
# Historia:
#
#        05-Mar-98 Alberto             Corregido un bug en la lecturadel fichero CfgConfig.CFG
#                                      que provocaba un malfuncionamiento con frontL10.
#        03-Dic-97 Alberto             Cambio a nuevo estilo de volcadoscon extension txx, pero
#                                      manteniendo compatibilidad conlos antiguos .tz. En el
#                                      servidor puente se hace un enviodoble, al directorio
#                                      PorEnviar y al Enviados, que allihace de backup.
#        25-Nov-97 Alberto             Mejora estetica del fichero log.
#        12-Nov-97 Alberto             Aumento de la informacion enviadaal fichero de log.
#        11-Nov-97 Alberto             Paso a switches de losdirectorios de volcados
#                                      y de enviados y uso dedirectorios por defecto
#                                      y fichero de log por defecto.
#        06-Sep-97 Alberto             Usa check_host en lugar de ping ycmd_tout si estan
#                                      presentes. Nombre de ficheroincluye hostname. Modo
#                                      de prueba (-t). Adaptacion apeculiaridades del HP/UX.
#                                      ademas de localizacion.
#                                          Tras varios intentos fallidosde hacerlo de otra
#                                      manera empleo las funciones decerrojos remotos para
#                                      exclusion mutua.
#        02-Sep-97 Alberto             Inicio codigo.
#
# Por hacer:
#        ¸ Mandar a ambos directorios en el servidor de datos puente; enel Enviados distribuirlo
#          en directorios.
#        ¸ Devolver distintos codigos de retorno para diferenteserrores.
#        ¸ Niveles de depurado (verbose).
#        ¸ Mandar tambien fichero con informacion de los hosts.
#        ¸ No ejecutar MandaVolcados.ksh en el servidor de datos puente(sino el programa
#          de distribucion).
#        ¸ Las funciones de cerrojos remotos deben tener un 'fallback'si no existe el
#          comando cmd_tout. Lo mejor es aprovechar el codigo que hay enel programa
#          principal.
#
# NOTAS:
#        ¸ Por defecto:
#           - Directorio volcados: $HOME/sistema/V/Volcados/PorEnviar
#           - Directorio enviados: $HOME/sistema/V/Volcados/Enviados
#           - Fichero log: $HOME/sistema/V/Volcados/FicheroLog
#

#
# Parametros configurables del programa:
#
# ¸ hostname del servidor de datos puente normal y de prueba (-t).
hnservdat_normal="siryd2"
hnservdat_prueba="alberto"
# ¸ Tiempo de espera para el comando cmd_tout.
tout_cmd=40
# ¸ Nombre del fichero de configuracion normal y de prueba (opcion -t).
cfgfile_normal=/home/metro/sistema/V/CfgConfig.CFG
cfgfile_prueba=${HOME}/fuentes/volcados/CfgConfig_`uname -n`.CFG
# ¸ Directorios de volcados y enviados por defecto. En el servidorpuente
#   ${txdir} sirve como directorio de backup.
voldir=$HOME/sistema/V/Volcados/PorEnviar
txdir=$HOME/sistema/V/Volcados/Enviados
# ¸ Fichero de log.
logfname=$HOME/sistema/V/Volcados/FicheroLog
logfile=1 # Esto es por razones historicas.

#
# Primero se asegura de que tiene el path adecuado.
#
export PATH=/sbin:/usr/bin:/usr/sbin

#
#
# Funciones genericas de cerrojos remotos. 
#
#       ¸ lock_set:
#                    Argumentos: 
#                        cerrojo         Nombre (y path) del ficherocerrojo.
#                        host             Host remoto.
#
#                    Retorna:
#                        0                Se puede acceder.
#                        1                Hay otro procesoaccediendo.                
#                        2                Error en los permisos delfichero cerrojo.
#                        3                Error en acceso remoto.
#
#       ¸ lock_clear:
#                    Argumentos:
#                        cerrojo         Nombre (y path) del ficherocerrojo.
#                        host             Host remoto.
#
#                    Retorna:
#                        0                Ejecucion correcta, cerrojo abierto.
#                        1                Error accediendo al fichero cerrojo.
#
#
function lock_set {
    #
    # Concatena el hostname y el pid y lo concatena al fichero cerrojo.
    #
    mylock=`uname -n`.$$
    # Optimiza en el caso de que hostname == localhost
    if [[ $2 = "localhost" ]]; then
	print >>$1 ${mylock}
    else
	cmd_tout 40 ${rshcmd} $2 "echo >>$1 ${mylock}"
    fi
    if [[ $? -ne 0 ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_set: Error en rsh $2 echo >>${1} ${mylock}."
	fi
	return 3
    fi

    #
    # Comprueba si la primera linea del cerrojo corresponde a esteproceso,
    # es decir, ha sido el primero en crearlo.
    #
    if [[ $2 = "localhost" ]]; then
	locktest1=`cat $1 2>/dev/null`
    else
	locktest1=`cmd_tout 40 ${rshcmd} $2 "cat $1" 2>/dev/null`
    fi
    if [[ $? -ne 0 ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_set: Error en rsh cat."
	fi
	return 3
    fi
    set -A locktest2 ${locktest1}
    if [[ ${locktest2[0]} = $mylock ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_set: OK."
	fi
	return 0
    fi

    if [[ ${locktest2[0]} = "" ]]; then
	# Otro proceso ha hecho un lock_clear y le ha pillado enmedio.
	# Sale igual que si el cerrojo estuviese cerrado.
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_set: Otro proceso ha hecho lock_clear."
	fi
	return 1
    fi

    if [[ ${debug} -eq 1 ]]; then
	print "lock_set: Cerrojo cerrado por ${locktest2[0]}"
    fi

    #
    # Intenta averiguar si el proceso due±o del cerrojo esta vivo o no.
    #
    lock_host=${locktest2[0]%%.*}
    lock_pid=${locktest2[0]##*.}
    local_host=`uname -n`

    if [[ ${debug} -eq 1 ]]; then
	print "lock_set: Comprobando proceso ${lock_pid} en ${lock_host}"
    fi

    if [[ ${lock_host} = ${local_host}  || ${lock_host} = "localhost" ]]; then
	# El proceso es de esta misma maquina.
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_set: ${lock_host} es localhost."
	fi
#	/usr/bin/ps -efa | awk '{print $2}' | grep ${lock_pid} >/dev/null 2>&1
	/usr/bin/ps -efa | grep ${lock_pid} | grep Manda_Volcados >/dev/null 2>&1
	if [[ $? -eq 1 ]]; then
	    # El proceso no existe, se puede reventar su cerrojo.
	    if [[ ${debug} -eq 1 ]]; then
		print "lock_set: No existe ${lock_pid} en ${lock_host}. Reventando cerrojo."
	    fi
	    if [[ $2 = "localhost" ]]; then
		rm -f $1
		if [[ $? -ne 0 ]]; then
		    if [[ ${debug} -eq 1 ]]; then
			print "lock_set: Error reventando cerrojo local."
		    fi
		fi
	    else
		cmd_tout 40 ${rshcmd} $2 "rm -f $1"
		if [[ $? -ne 0 ]]; then
		    if [[ ${debug} -eq 1 ]]; then
			print "lock_set: Error reventando cerrojo remoto."
		    fi
		fi
	    fi
	else
	    if [[ ${debug} -eq 1 ]]; then
		print "lock_set: cerrojo a”n valido."
	    fi
	fi
    else
	# El proceso es de una maquina remota.
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_set: ${lock_host} es remoto."
	fi
	pidtest=`cmd_tout 40 ${rshcmd} ${lock_host} "/usr/bin/ps -efa | awk '{print \\$2}' | grep ${lock_pid}"`
	if [[ ${pidtest} != ${lock_pid} ]]; then
	    # El proceso no existe, se puede reventar su cerrojo.
	    if [[ ${debug} -eq 1 ]]; then
		print "lock_set: No existe ${lock_pid} en ${lock_host}. Reventando cerrojo."
	    fi
	    if [[ $2 = "localhost" ]]; then
		rm -f $1
		if [[ $? -ne 0 ]]; then
		    if [[ ${debug} -eq 1 ]]; then
			print "lock_set: Error reventando cerrojo local."
		    fi
		fi
	    else
		cmd_tout 40 ${rshcmd} $2 "rm -f $1"
		if [[ $? -ne 0 ]]; then
		    if [[ ${debug} -eq 1 ]]; then
			print "lock_set: Error reventando cerrojo remoto."
		    fi
		fi
	    fi
	else
	    if [[ ${debug} -eq 1 ]]; then
		print "lock_set: cerrojo a”n valido."
	    fi
	fi
    fi

    return 1       
} # function lock_set

function lock_clear {
    if [[ $2 = "localhost" ]]; then
	val=`rm -f $1`
    else
	val=`cmd_tout 40 ${rshcmd} $2 rm -f $1`
    fi
    if [[ $? -ne 0 ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "lock_clear: Error en rsh rm."
	fi
	return 1
    fi
    if [[ ${debug} -eq 1 ]]; then
	print "lock_clear: OK."
    fi
    return 0
} # function lock_clear

if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: `date` Inicio log."
fi
#
# Comprueba los argumentos de linea de comando.
#
debug=0
#logfile=0
cfgfile=${cfgfile_normal}
hnservdat=${hnservdat_normal}
while getopts ":dtl:v:e:" option ${*}
do
    case ${option} in
	d)
	    debug=1
	    print "${0##*/}: Depurado activado."
	    ;;
	t)
	    cfgfile=${cfgfile_prueba}
	    hnservdat=${hnservdat_prueba}
	    ;;
	l)
	    logfile=1
	    logfname=${OPTARG}
	    ;;
	v)
	    voldir=${OPTARG}
	    ;;
	e)
	    txdir=${OPTARG}
	    ;;
	*)
	    cat <<EOF
Error: Opcion desconocida: ${OPTARG}

Uso: ${0##*/} [-d] [-l <logfile>] [-v <directorio_volcados>] [-e <directorio_enviados>]

EOF
	    if [[ ${logfile} -eq 1 ]]; then
		print >>${logfname} 2>&1 "${0##*/}: Error en argumentos."
	    fi
	    exit 1
	    break
	    ;;
    esac
done
shift OPTIND-1  # Se salta las opciones y apunta a los directorios.
# Como minimo debe haber ahora dos argumentos.
if [[ $# -ne 0 ]]; then
    cat <<EOF
Error: Demasiados argumentos.

Uso: ${0##*/} [-d] [-l <logfile>] [-v <directorio_volcados>] [-e <directorio_enviados>]

EOF
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error en argumentos."
    fi
    exit 1
fi
#
# Recoge el nombre directorio de volcados y el de enviados.
# Se asegura de que los directorios no tienen al final un '/'.
#
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Directorio de volcados: ${voldir}, de enviados: ${txdir}"
    print "${0##*/}: Fichero de configuracion ${cfgfile}"
    print "${0##*/}: Fichero de logs: ${logfname}"
fi
if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}:"
    print >>${logfname} 2>&1 "	Directorio de volcados: ${voldir}"
    print >>${logfname} 2>&1 "	Directorio de enviados: ${txdir}"
fi

#
# Mira si ya hay una instancia de este programa corriendo.
#
lock_set "${voldir}/.lock" "localhost"
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Ya hay otro proceso corriendo."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Ya hay otro proceso corriendo."
    fi
    exit 0
fi

#
# Comprueba que los directorio existen y se puede usar.
#
if [[ ! -d ${voldir} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Directorio: ${voldir} no valido."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Directorio: ${voldir} no valido."
    fi
    lock_clear "${voldir}/.lock" "localhost"
    exit 1
fi
if [[ ! -x ${voldir} || ! -r ${voldir} || ! -w ${voldir} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Sin permiso para usar directorio ${voldir}."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Sin permiso para usar directorio ${voldir}."
    fi
    lock_clear "${voldir}/.lock" "localhost"
    exit 1
fi
if [[ ! -d ${txdir} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Directorio: ${txdir} no valido."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Directorio: ${txdir} no valido."
    fi
    lock_clear "${voldir}/.lock" "localhost"
    exit 1
fi
if [[ ! -x ${txdir} || ! -w ${txdir} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Sin permiso para usar directorio ${txdir}."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Sin permiso para usar directorio ${txdir}."
    fi
    lock_clear "${voldir}/.lock" "localhost"
    exit 1
fi

#
# Comprueba si hay algo que mandar, es decir, ficheros con nombre Mddlleev_host_proceso.txx,
# o ficheros con nombre Mddhhmmss_host_proceso.vxx
# donde:
#
#         M  es el mes (EFMAYJLGSOND).
#         dd el dia del mes (con un cero a la izquierda si fuese necesario).
#         ll el numero de linea
#         ee el numero de estacion
#         v  el numero de vestibulo.
#         hh hora actual
#         mm minuto actual
#         ss segundo actual
#         host es el hostname.
#         proceso es un nombre de proceso que ha solicitado el volcado. Puede no estar.
#         xx es un n”mero de orden para volcados del mismo proceso en el mismo dia (01 a 99).
#         xx es un número de orden para volcados en el mismo segundo (01 a 99).

#
# Se mantiene la compatibilidad con un formato antiguo de volcado con extension tz.
#
cd ${voldir}
files=$(ls [A-Z][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_*.t+([z0-9]) 2>/dev/null)
if [[ $? -ne 0 ]]; then
    files=$(ls [A-Z][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_*.v+([0-9]) 2>/dev/null)
    if [[ $? -ne 0 ]]; then
    	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Ningun fichero por enviar."
    	fi
    	if [[ ${logfile} -eq 1 ]]; then
	    print >>${logfname} 2>&1 "${0##*/}: Ningun fichero por enviar."
    	fi
    	lock_clear "${voldir}/.lock" "localhost"
    	exit 0
    fi
fi

#
# Determina el sistema operativo del host y se adapta a sus peculiaridades
#
hostOS=`uname -s`
case ${hostOS} in
    HP-UX)
	rshcmd="/usr/bin/remsh"
	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Sistema operativo HP/UX, rsh es ${rshcmd}."
	fi
	;;
    *)
	rshcmd="/usr/bin/rsh"
	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Sistema operativo Solaris, rsh es ${rshcmd}."
	fi
	;;
esac

#
# Averigua a partir del fichero /home/metro/sistema/CfgConfig.CFG el nombre del
# host al que debe mandar por rcp los ficheros del directorio.
#

#
# Procesa el fichero CfgConfig.CFG. Extrae localizacion en el array lev:
#
#           lev[0] linea
#           lev[1] estacion
#           lev[2] vestibulo
#
# Ademas indica en la variable host el tipo de maquina: pcl, vest, vest2, front,
# y en la variable boss el nodo que esta jerarquicamente por encima. Tambien:
#
#           ¸ pcl: guarda en las variables vest y vest2 los hostnames del
#                  segundo y tercer vestibulo (si existen).
#
#           ¸ front: guarda en la variable estaciones la lista de estaciones
#                    que cuelgan de este frontend.
#
{ while read line; do
    # Procesa el fichero linea a linea.
    if [[ $line = +([0-9])+([${IFS}])+([0-9])+([${IFS}])[0-9] ]]; then
	    set -A lev $line
    elif [[ $line = "CONCENTRADOR PRINCIPAL" ]]; then
	    host=pcl
	    if [[ ${debug} -eq 1 ]]; then
		print "${0##*/}: Es un PCL."
	    fi
    elif [[ $line = "CONCENTRADOR SECUNDARIO" ]]; then
	    case ${lev[2]} in
		2)
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un segundo vestibulo."
		    fi
		    host=vest
		    ;;
		3)  
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un tercer vestibulo."  
		    fi
		    host=vest2
		    ;;
		4)  
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un cuarto vestibulo."  
		    fi
		    host=vest3
		    ;;
		5)  
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un quinto vestibulo."  
		    fi
		    host=vest4
		    ;;
		6)  
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un sexto vestibulo."  
		    fi
		    host=vest5
		    ;;
		*)
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un vestibulo ${lev[2]}"
		    fi
		    ;;
	    esac
    elif [[ $line = "CONCENTRADOR FRONT-END PRIMARIO" ]] || [[ $line = "CONCENTRADOR FRONT-END SECUNDARIO" ]]; then
	    host=front
	    if [[ ${debug} -eq 1 ]]; then
		print "${0##*/}: Es un frontend."
	    fi
    elif [[ $line = +([0-9])+([${IFS}])+([0-9])+([${IFS}])+([0-9])+([${IFS}])* ]]; then
	    set -A btmp $line
	    case ${host} in
		vest|vest2|vest3|vest4|vest5)
		    # La unica linea de este tipo indica el pcl.
		    boss=`echo ${btmp[3]} | cut -f1 -d'@'`
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Su pcl es: ${boss}"
		    fi
		    ;;
		pcl)
		    # Hay dos o tres lineas, una o dos para los vestibulos
		    # y una para el frontend. Esta ultima se distingue porque
		    # sus numeros de linea y estacion son cero. Los vestibulos
		    # se distiguen por su numero de vestibulo, 2 o 3.
		    if [[ ${btmp[0]} -eq 0 && ${btmp[1]} -eq 0 ]]; then
			# Es un pcl.			
			boss=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Su frontend es: ${boss}"
			fi
		    elif [[ ${btmp[2]} -eq 2 ]]; then
			# Segundo vestibulo.
			vest=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene segundo vestibulo: ${vest}"
 			fi
		    elif [[ ${btmp[2]} -eq 3 ]]; then
			# Tercer vestibulo.
			vest2=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene tercer vestibulo: ${vest2}"
 			fi
		    elif [[ ${btmp[2]} -eq 4 ]]; then
			# Cuarto vestibulo.
			vest3=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene cuarto vestibulo: ${vest3}"
 			fi
		    elif [[ ${btmp[2]} -eq 5 ]]; then
			# Quinto vestibulo.
			vest4=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene quinto vestibulo: ${vest4}"
 			fi
		    elif [[ ${btmp[2]} -eq 6 ]]; then
			# Sexto vestibulo.
			vest4=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene sexto vestibulo: ${vest5}"
 			fi
		    fi
		    ;;
		front)
		    # El Puesto Central se distingue de nuevo por tener linea
		    # y estacion a cero (y vestibulo realmente). El resto de
		    # lineas son las estaciones que maneja.
		    if [[ ${btmp[0]} -eq 0 && ${btmp[1]} -eq 0 ]]; then
			# Es el Puesto Central.
			boss=`echo ${btmp[3]} | cut -f1 -d'@'`
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Puesto central con el que se comunica: ${vest}"
 			fi
		    else
			# Estaciones que tiene por debajo
			estaciones="${estaciones} `echo ${btmp[3]} | cut -f1 -d'@'`"
		    fi
		    ;;
		*)
		    # Puesto central y puesto de operador. XXX: Tenerlos en cuenta.
		    ;;
	    esac
    elif [[ $line = "FIN" ]]; then
	    #print "${0##*/}: FIN"
	    break;
    fi
done } < ${cfgfile}
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Error accediendo a CfgConfig.CFG."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error accediendo a CfgConfig.CFG."
    fi
    lock_clear "${voldir}/.lock" "localhost"
    exit 1
fi


if [[ ${debug} -eq 1 && ${host} = "front" ]]; then
    print "${0##*/}: Estaciones que cuelgan: ${estaciones}"
fi

#print ${host} en ${lev[*]}.

#
# En el caso del frontend, los ficheros no se mandan al Puesto Central, sino al
# servidor de datos puente.
#
if [[ ${host} = "front" ]]; then
    boss=${hnservdat}
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Frontend envia a ${boss}"
    fi
fi

#
# Comprueba que hay comunicacion con el host. Usa check_host y cmd_toutsi es posible.
#
#if [[ -x `which check_host` ]]; then
if [[ -x /usr/local/bin/check_host ]]; then
    ping_cmd="/usr/local/bin/check_host ${boss}"
    if [[ ${host} = "pcl" ]]; then
    	ping_rcmd="/usr/local/bin/check_host r${boss}"
    fi
else
    case ${hostOS} in
	HP-UX)
	    ping_cmd="/usr/sbin/ping ${boss} -n 1"
	    if [[ ${host} = "pcl" ]]; then
	    	ping_rcmd="/usr/sbin/ping r${boss} -n 1"
	    fi
	    ;;
	*)
	    ping_cmd="/usr/sbin/ping ${boss}"
	    if [[ ${host} = "pcl" ]]; then
	    	ping_rcmd="/usr/sbin/ping r${boss}"
	    fi
	    ;;
    esac
fi
#if [[ -x `which cmd_tout` ]]; then
if [[ -x /usr/local/bin/cmd_tout ]]; then
    ping_cmd="/usr/local/bin/cmd_tout ${tout_cmd} ${ping_cmd}"
    if [[ ${host} = "pcl" ]]; then
    	ping_rcmd="/usr/local/bin/cmd_tout ${tout_cmd} ${ping_rcmd}"
    fi
fi

if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Comando que comprueba host: ${ping_cmd}."
    if [[ ${host} = "pcl" ]]; then
    	print "${0##*/}: Comando que comprueba rhost: ${ping_rcmd}."
    fi
fi

${ping_cmd} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Sin comunicacion con ${boss}."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Sin comunicacion con ${boss}."
    fi
    if [[ ${host} = "pcl" ]]; then
    	${ping_rcmd} >/dev/null 2>&1
    	if [[ $? -ne 0 ]]; then
    	    if [[ ${debug} -eq 1 ]]; then
		print "${0##*/}: Sin comunicacion con r${boss}. Saliendo."
    	    fi
    	    if [[ ${logfile} -eq 1 ]]; then
		print >>${logfname} 2>&1 "${0##*/}: Sin comunicacion con r${boss}."
    	    fi
    	    lock_clear "${voldir}/.lock" "localhost"
    	    exit 1
	else
    	    boss="r${boss}"
	    if [[ ${debug} -eq 1 ]]; then
		print "${0##*/}: El nuevo boss es el replica ${boss}."
    	    fi
    	    if [[ ${logfile} -eq 1 ]]; then
		print >>${logfname} 2>&1 "${0##*/}: El nuevo boss es el replica ${boss}."
    	    fi
	fi
    else
    	lock_clear "${voldir}/.lock" "localhost"
    	exit 1
    fi
fi

#
# Genera un nombre temporal con el que se manda inicialmente el fichero.
#
HostName=`uname -n`
echo "${HostName}"
tmpfname=/tmp/.MandaVolcados.ksh.$$.${HostName}

#
# Manda los ficheros uno a uno (para tener control de cuales llegan y cuales no).
#
for file in ${files}; do
    #
    # Envia el fichero. Usa la opcion -p para intentar tener la misma fecha y
    # permisos que el original. Usa un nombre temporal para evitar que se
    # empiece a mandar un fichero llegado a medias.
    #
    if [[ ${logfile} -eq 1 ]]; then
        print >>${logfname} 2>&1 "${0##*/}: `date` "
        print >>${logfname} 2>&1 "${0##*/}: Nombre temporal fichero ${file} sera ${tmpfname##*/}"
    fi
    rcp -p ${file} ${boss}:${voldir}/${tmpfname##*/} >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Error enviando fichero ${file} a ${voldir}/${tmpfname##*/} de ${boss}"
	fi
	if [[ ${logfile} -eq 1 ]]; then
	    print >>${logfname} 2>&1 "${0##*/}: Error enviando fichero ${file} a ${voldir}/${tmpfname##*/} de ${boss}"
	fi
	lock_clear "${voldir}/.lock" "localhost"
	exit 1
    fi

    #
    # Renombra el fichero enviado para indicar que esta completo.
    #
    if [[ ${logfile} -eq 1 ]]; then
        print >>${logfname} 2>&1 "${0##*/}: `date` "
        print >>${logfname} 2>&1 "${0##*/}: Movemos remotamente el ${tmpfname##*/} a ${file}"
    fi
    ${rshcmd} ${boss} mv ${voldir}/${tmpfname##*/} ${voldir}/${file} >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Error renombrando ${voldir}/${tmpfname} a ${voldir}/${file} en ${boss}"
	fi
	if [[ ${logfile} -eq 1 ]]; then
	    print >>${logfname} 2>&1 "${0##*/}: Error renombrando ${voldir}/${tmpfname} a ${voldir}/${file} en ${boss}"
	fi
	${rshcmd} ${boss} rm -f ${voldir}/${tmpfname##*/} >/dev/null 2>&1
	lock_clear "${voldir}/.lock" "localhost"
	exit 1
    fi

    # Si esta en un frontend, hay que hacer un segundo envio al servidor de datos puente del
    # fichero al directorio de enviados, que en este caso es de backup. El fichero debe ir
    # a un subdirectorio del dia. Por otra parte en el puente no se ejecuta MandaVolcados.
    if [[ ${host} = "front" ]]; then
	# Averigua el nombre del directorio dentro de ${txdir} donde se debe guardar el fichero.
	# Consiste en Mdd (los tres primeros caracteres).
	mdd_dirname=${file%[0-9][0-9][0-9][0-9][0-9]_*.t+([z0-9])}
	# Crea el directorio si es necesario.
	${rshcmd} ${boss} mkdir ${txdir}/${mdd_dirname} >/dev/null 2>&1
	# Copia el fichero en el directorio. Implicitamente detecta si hubo un error en el comando
	# anterior.
	rcp -p ${file} ${boss}:${txdir}/${mdd_dirname}/${file} >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
	    if [[ ${debug} -eq 1 ]]; then
		print "${0##*/}: Error enviando fichero ${file} a ${txdir}/${mdd_dirname}/ de ${boss}"
	    fi
	    if [[ ${logfile} -eq 1 ]]; then
		print >>${logfname} 2>&1 "${0##*/}: Error enviando fichero ${file} a ${txdir}/${mdd_dirname}/ de ${boss}"
	    fi
	    lock_clear "${voldir}/.lock" "localhost"
	    exit 1
	fi
    else
	#
	# Ejecuta remotamamente MandaVolcados para que si hay comunicacion llegue
	# lo mas rapidamente posible.
	#
	if [[ ${test_on} -eq 1 ]]; then
	    mvcmd='${HOME}/volcados/MandaVolcados.ksh'
	    mvopts="-t"
	else
	    mvcmd="/home/metro/sun/MandaVolcados.ksh"
	    mvopts=""
	fi
	
	if [[ ${logfile} -eq 1 ]]; then
	    print >>${logfname} 2>&1 "${0##*/}: Arrancando ${mvcmd} en ${boss}"
	fi
	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Arrancando ${mvcmd} en ${boss}"
	fi
	${rshcmd} ${boss} ${mvcmd} ${mvopts} >/dev/null 2>&1 &
    
    fi

#    if [[ ${logfile} -eq 1 ]]; then
#	print >>${logfname} 2>&1 "${0##*/}: `date` Fin log."
#    fi
    
    #
    # Una vez mandado con exito, pasa el fichero al directorio de enviados.
    #
    if [[ ${debug} -eq 1 ]]; then
	# Comprueba que no exista ya un fichero con el mismo nombre. En ese caso
	# refleja el error pero continua.
	if [[ -a ${txdir}/${file} ]]; then
	    print "${0##*/}: Ya existia ${txdir}/${file}."
	fi
    fi
    if [[ ${logfile} -eq 1 ]]; then
        print >>${logfname} 2>&1 "${0##*/}: `date` "
        print >>${logfname} 2>&1 "${0##*/}: Movemos ${file} a ${txdir}"
    fi
    mv -f ${file} ${txdir} >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "${0##*/}: Error moviendo ${voldir}/${file} a ${txdir}."
	fi
	if [[ ${logfile} -eq 1 ]]; then
	    print >>${logfname} 2>&1 "${0##*/}: Error moviendo ${voldir}/${file} a ${txdir}."
	fi
	lock_clear "${voldir}/.lock" "localhost"
	exit 1
    fi

    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Fichero ${voldir}/${file} en ${boss} creado OK."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Fichero ${voldir}/${file} en ${boss} creado OK."
    fi
done

if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: `date` Fin log."
fi

#
# Desbloquea el directorio.
#
lock_clear "${voldir}/.lock" "localhost"

exit 0

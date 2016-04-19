#!/bin/ksh -p
#
# CreaVolcado.ksh: Crea un nuevo volcado, es decir, prepara un archivo tar comprimido con
#                  gzip de los ficheros y/o directorios indicados y lo manda al directorio
#                  de volcados para que MandaVolcados.ksh lo env�e a la jerarqu�a
#                  superior (vest -> pcl -> front -> puente). De haber comunicaci�n el
#                  env�o es inmediato; si no se reintenta peri�dicamente (ver
#                  MandaVolcados.ksh).
#
# Uso: /home/metro/sun/CreaVolcado.ksh [-d] [-t] [-l <logfile>] [-v <directorio_volcados>]
#                   [-e <directorio_enviados>] [-p <nombre_proceso>]
#                   <fichero o directorio> [<fichero o directorio> ...]
#
#      -d: activa depurado.
#      -t: Modo de prueba. El fichero CfgConfig.CFG que se lee es el de la variable
#          cfgfile_prueba en lugar de cfgfile_normal (ver m�s abajo).
#      -l <logfile>: Selecciona un fichero de log distinto del por defecto.
#                    El fichero debe tener path absoluto.
#      -v <directorio_volcados>: Selecciona un directorio de volcados distinto del de por
#                                defecto. Debe tener path absoluto.
#      -e <directorio_enviados>: Selecciona un directorio de enviados distinto del de por
#                                defecto, con path absoluto.
#      -p <nombre_proceso>: Indica un nombre de proceso para distinguir volcados del mismo
#                           dia en el mismo host. Es opcional.
#
# C�digos de retorno:
#
#      0      Todo bien (no asegura su env�o inmediato).
#      9      Error en argumentos.
#      2      Directorio de volcados no existe.
#      3      Directorio de volcados no tiene permisos adecuados (wx).
#      4      Error accediendo al fichero CfgConfig.CFG.
#      5      Error en tar creando fichero de volcados.
#      6      Error en gzip creando fichero de volcados.
#      7      Error moviendo volcado al directorio de volcados.
#      8      Error dando nombre definitivo al fichero volcado.
#
#
# Historia:
#
#        06-Oct-98 Ana	               Ampliar el significado de la extension txx/mxx para 
#				       que la correlatividad se refiera a numero de volcados por
#				       tipo de proceso en un dia (no a numero de volcados para 
#				       el mismo proceso en un dia).
#        04-Dic-97 Alberto             Agosto se representa por la letra G en lugar de por la A.
#        03-Dic-97 Alberto             Recorta tambi�n el nombre de subsistema (Pupitre, p. ej.)
#                                      del path,
#        02-Dic-97 Alberto             Los nombres de volcados cambian para soportar m�s de
#                                      un volcado diario por proceso. Ahora son t01..t99. Por
#                                      otra parte se hace el volcado con path relativo a 
#                                      $HOME/sistema/V.
#        25-Nov-97 Alberto             En modo depurado el tar es ecvf en lugar de ecf.
#                                      Los argumentos y el stderr del tar van a logfile.
#                                      Mejora est�tica del fichero log.
#        12-Nov-97 Alberto             Nuevo switch con el nombre de proceso. Cambio en
#                                      los c�digos de retorno de error para evitar el 1
#                                      que puede devolver sh al hacer system().
#        11-Nov-97 Alberto             Paso a switches de los directorios de volcados
#                                      y de enviados y uso de directorios por defecto
#                                      y fichero de log por defecto.
#        06-Sep-97 Alberto             Nombre de fichero incluye hostname adem�s de
#                                      localizaci�n. Modo de prueba (-t).
#        02-Sep-97 Alberto             Inicio c�digo. Me inspiro en los scrips del
#                                      distribuidor.
#
# Por hacer:
#
#        � El tar:
#
#                tar ecvf ${tmpfname} -C ${path_rm_nw} ${tar_files[*]} 2>&1
#
#          genera un error cuando tar_files tiene m�s de un elemento. Deber�a
#          repetirse la opci�n -C para cada uno de ellos y no solo para el
#          primero.
#        � Mandar tambi�n fichero con informaci�n del host.
#        � Niveles de depurado (verbose).
#
# NOTAS:
#        � Por defecto:
#           - Directorio volcados: $HOME/sistema/V/Volcados/PorEnviar
#           - Directorio enviados: $HOME/sistema/V/Volcados/Enviados
#           - Fichero log: $HOME/sistema/V/Volcados/FicheroLog
#
#        � Los ficheros y/o directorios que no empiecen por ${path_rm} se empaquetan
#          con path absoluto. Si ${path_rm} tiene wildcards y casan varios ficheros
#          o directorios (argumentos del tar) con path distinto el volcado puede no
#          contener lo esperado.

# Primero se asegura de que tiene el path adecuado.
#
export PATH=.:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

#
# Par�metros configurables del programa:
#
# � Nombre del fichero de configuraci�n normal y de prueba (opci�n -t).
cfgfile_normal=${HOME}/sistema/V/CfgConfig.CFG
cfgfile_prueba=${HOME}/fuentes/volcados/CfgConfig_`uname -n`.CFG
# � Directorios de volcados y enviados por defecto.
voldir=${HOME}/sistema/V/Volcados/PorEnviar
txdir=${HOME}/sistema/V/Volcados/Enviados
# � Nombre de proceso por defecto. "" para ninguno.
nproceso=""
# � Fichero de log.
logfname=$HOME/sistema/V/Volcados/FicheroLog
logfile=1 # Esto es por razones hist�ricas.
# � Fichero que indica el n�mero de volcado en el d�a por proceso.
lastfname=$HOME/sistema/V/Volcados/.UltimoHoy
# � Parte del path que se elimina en el tar para hacer que sea relativo.
path_rm=${HOME}/sistema/V/*/
#path_rm=${HOME}/sistema/V/*/*/

#
# Comprueba los argumentos de l�nea de comando.
#
debug=0
cfgfile=${cfgfile_normal}
test_on=0
while getopts ":dtl:v:e:p:" option ${*}
do
    case ${option} in
	d)
	    debug=1
	    print "${0##*/}: Depurado activado."
	    ;;
	t)
	    test_on=1
	    cfgfile=${cfgfile_prueba}
	    ;;
	l)
	    #logfile=1
	    logfname=${OPTARG}
	    print >>${logfname} 2>&1 "${0##*/}: `date` Inicio log."
	    ;;
	v)
	    voldir=${OPTARG}
	    ;;
	e)
	    txdir=${OPTARG}
	    ;;
	p)
	    nproceso=${OPTARG}
	    ;;
	*)
	    cat <<EOF
Error: Opci�n desconocida: ${OPTARG}

Uso: ${0##*/} [-d] [-l <logfile>] [-v <directorio>] [-e <directorio>] [-p <nombre_proceso>] <fichero_o_directorio> [<fichero_o_directorio>...]

EOF
	    if [[ ${logfile} -eq 1 ]]; then
		print >>${logfname} 2>&1 "${0##*/}: Error en argumentos."
	    fi
	    exit 9
	    break
	    ;;
    esac
done
shift OPTIND-1  # Se salta las opciones y apunta a los ficheros.
# Como m�nimo debe haber ahora tres argumentos.
if [[ $# -lt 1 ]]; then
    cat <<EOF
Error: Argumentos insuficientes.

Uso: ${0##*/} [-d] [-l <logfile>] [-v <directorio>] [-e <directorio>] [-p <nombre_proceso>] <fichero_o_directorio> [<fichero_o_directorio>...]

EOF
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error en argumentos."
    fi
    exit 9
fi
# Deja $* con los ficheros y directorios
# que se deben archivar.
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Directorio de volcados: ${voldir}, de enviados: ${txdir}"
    print "${0##*/}: Proceso: ${nproceso}"
    print "${0##*/}: Fichero de configuraci�n ${cfgfile}"
fi
if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: ${nproceso}"
    print >>${logfname} 2>&1 "	Directorio de volcados: ${voldir}"
    print >>${logfname} 2>&1 "	Directorio de enviados: ${txdir}"
fi

#
# Comprueba que el directorio existe y se puede usar.
#
if [[ ! -d ${voldir} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Directorio: ${voldir} no v�lido."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Directorio: ${voldir} no v�lido."
    fi
    exit 2
fi
if [[ ! -x ${voldir} || ! -w ${voldir} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Sin permiso para usar directorio ${voldir}."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Sin permiso para usar directorio ${voldir}."
    fi
    exit 3
fi

#
# Averigua a partir del fichero /home/metro/sistema/CfgConfig.CFG el nombre del volcado, con
# formato Mddlleev_host_proceso.txx, donde:
#
#         M  es el mes (EFMAYJLGSOND).
#         dd el d�a del mes (con un cero a la izquierda si fuese necesario).
#         ll el n�mero de l�nea
#         ee el n�mero de estaci�n
#         v  el n�mero de vest�bulo.
#         host es el hostname.
#         proceso es un nombre de proceso que ha solicitado el volcado. Puede no estar.
#         xx es un n�mero de orden para volcados del mismo proceso en el mismo d�a (01 a 99).

#
# Crea un array con las letras que representan a los meses.
#
set -A meses E F M A Y J L G S O N D

#
# Procesa el fichero CfgConfig.CFG. Extrae localizaci�n en el array lev:
#
#           lev[0] l�nea
#           lev[1] estaci�n
#           lev[2] vest�bulo
#
# Adem�s indica en la variable host el tipo de m�quina: pcl, vest, vest2, front,
# y en la variable boss el nodo que est� jer�rquicamente por encima. Tambi�n:
#
#           � pcl: guarda en las variables vest y vest2 los hostnames del
#                  segundo y tercer vest�bulo (si existen).
#
#           � front: guarda en la variable estaciones la lista de estaciones
#                    que cuelgan de este frontend.
#
if [[ ! -r ${cfgfile} ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Error accediendo a ${cfgfile}"
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error accediendo a ${cfgfile}"
    fi
    exit 4
fi
{ while read line; do
    # Procesa el fichero l�nea a l�nea.
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
			print "${0##*/}: Es un segundo vest�bulo."
		    fi
		    host=vest
		    ;;
		3)  
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un tercer vest�bulo."  
		    fi
		    host=vest2
		    ;;
		*)
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Es un vest�bulo ${lev[2]}"
		    fi
		    ;;
	    esac
    elif [[ $line = "CONCENTRADOR FRONT-END" ]]; then
	    host=front
	    if [[ ${debug} -eq 1 ]]; then
		print "${0##*/}: Es un frontend."
	    fi
    elif [[ $line = +([0-9])+([${IFS}])+([0-9])+([${IFS}])[0-9]+([${IFS}])* ]]; then
	    set -A btmp $line
	    case ${host} in
		vest|vest2)
		    # La �nica l�nea de este tipo indica el pcl.
		    boss=${btmp[3]}
		    if [[ ${debug} -eq 1 ]]; then
			print "${0##*/}: Su pcl es: ${boss}"
		    fi
		    ;;
		pcl)
		    # Hay dos o tres l�neas, una o dos para los vest�bulos
		    # y una para el frontend. Esta �ltima se distingue porque
		    # sus n�meros de l�nea y estaci�n son cero. Los vest�bulos
		    # se distiguen por su n�mero de vest�bulo, 2 o 3.
		    if [[ ${btmp[0]} -eq 0 && ${btmp[1]} -eq 0 ]]; then
			# Es un pcl.
			boss=${btmp[3]}
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Su frontend es: ${boss}"
			fi
		    elif [[ ${btmp[2]} -eq 2 ]]; then
			# Segundo vest�bulo.
			vest=${btmp[3]}
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene segundo vest�bulo: ${vest}"
 			fi
		    elif [[ ${btmp[2]} -eq 3 ]]; then
			# Tercer vest�bulo.
			vest2=${btmp[3]}
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Tiene tercer vest�bulo: ${vest2}"
 			fi
		    fi
		    ;;
		front)
		    # El Puesto Central se distingue de nuevo por tener l�nea
		    # y estaci�n a cero (y vest�bulo realmente). El resto de
		    # l�neas son las estaciones que maneja.
		    if [[ ${btmp[0]} -eq 0 && ${btmp[1]} -eq 0 ]]; then
			# Es el Puesto Central.
			boss=${btmp[3]}
			if [[ ${debug} -eq 1 ]]; then
			    print "${0##*/}: Puesto central con el que se comunica: ${vest}"
 			fi
		    else
			# Estaciones que tiene por debajo
			estaciones="${estaciones} ${btmp[3]}"
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

if [[ ${debug} -eq 1 && ${host} = "front" ]]; then
    print "${0##*/}: Estaciones que cuelgan: ${estaciones}"
fi

#print ${host} en ${lev[*]}.

#
# Averigua la fecha, mes y d�a.
#
mes=$(date '+%m')
dia=$(date '+%d')

#
# Comprueba si es el primer volcado del d�a para este proceso. Para ello lee
# el fichero ${lastfname} y genera los arrays lastvolproc y lastvolnum, ademas
# de la variable lastcount con el n�mero de elementos del d�a. Los elementos que
# no sean del d�a se ignoran. Si aparece el proceso actual, en la variable
# lastidx aparece el �ndice. Si no es -1.
#
# La estructura del fichero es la siguiente:
#
#    Dia      Proceso      indice
#
# El d�a es con el formato del nombre de fichero, es decir, por ejemplo D02 para el
# 2-Diciembre. El nombre de proceso es NULL para indicar que no tiene, y el �ndice el
# corrspondiente al siguiente volcado.
#
#
lastcount=0
lastidx=-1
lasttoday=${meses[mes-1]}${dia}
if [[ -a ${lastfname} ]]; then
    if [[ -r ${lastfname} && -w ${lastfname} ]]; then
	strings ${lastfname} | { while read line; do
	    # Procesa el fichero l�nea a l�nea.
	    if [[ $line = [A-Z]+([0-9])+([${IFS}])+([0-9A-Za-z])+([${IFS}])+([0-9]) ]]; then
		if [[ ${debug} -eq 1 ]]; then
		    print "L�nea reconocida: ${line}"
		fi
		set -A last_decod $line
		if [[ ${last_decod[0]} = ${lasttoday} ]]; then
		    if [[ ${debug} -eq 1 ]]; then
			print "L�nea del d�a."
		    fi
		    if [[ ${last_decod[1]} = "NULL" ]]; then
			last_decod[1]=""
		    fi
		    lastproc[${lastcount}]=${last_decod[1]}
		    lastvolnum[${lastcount}]=${last_decod[2]}

		    if [[ ${last_decod[1]} = ${nproceso} ]]; then
			if [[ ${debug} -eq 1 ]]; then
			    print "Proceso actual, �ndice ${lastcount}, contador ${lastvolnum[${lastcount}]}"
			fi
			lastidx=${lastcount}
		    fi

		    (( lastcount+=1 ))

		else
		    if [[ ${debug} -eq 1 ]]; then
			print "L�nea no del d�a. Ignorada."
		    fi
		fi
	    fi
	done }

    else
	# El fichero no tiene los permisos adecuados. Intenta borrarlo y crear uno nuevo
	# vac�o.
	if [[ ${debug} -eq 1 ]]; then
	    print "Borrando ${lastfname} err�neo." 
	fi
	rm -rf ${lastfname} 2>&1
    fi
fi

#
# Extraemos el numero de volcado de procesos de este tipo "numvol".
# Es lo que realmente usaremos para poner la extension al fichero
#
integer j=0
case ${nproceso} in
    PPT*)
      tipo="PPT"
      ;;
    METT*)
      tipo="MET"
      ;;
    MBT*)
      tipo="MBT"
      ;;
    *)
      tipo="kk"
      ;;
esac

integer numvol=0
while [[ ${j} -lt ${lastcount} ]]; do
    proceso=${lastproc[${j}]}
    name=${proceso%?????}
    if [[ ${tipo} = ${name} ]]; then
        (( vol=${lastvolnum[${j}]} ))
        (( vol-=1 ))
        (( numvol+=${vol} ))
    fi
    (( j+=1 ))
done
(( numvol+=1 ))
if [[ ${numvol} -eq 0 ]]; then
   numvol=1 
fi


# De no existir una l�nea para el d�a y proceso actuales, a�ade un elemento al array.
if [[ ${lastidx} -eq -1 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "Primer fichero del d�a para proceso ${nproceso}"
    fi
    lastproc[${lastcount}]=${nproceso}
    lastvolnum[${lastcount}]=1
    lastidx=${lastcount}
    (( lastcount+=1 ))
fi

#
# Genera con la informaci�n disponible el nombre del fichero por crear. La
# instrucci�n typeset hace que los n�meros de l�nea y estaci�n ocupen exactamente
# dos caracteres, con ceros a la izquierda si fuese necesario.
#
typeset -Z2 linea=${lev[0]}
typeset -Z2 estacion=${lev[1]}
#typeset -Z2 count=${lastvolnum[${lastidx}]}
typeset -Z2 count=${numvol}
vestibulo=${lev[2]}
if [[ ${nproceso} != "" ]]; then
    fname=${meses[mes-1]}${dia}${linea}${estacion}${vestibulo}_`uname -n`_${nproceso}.t${count}
else
    fname=${meses[mes-1]}${dia}${linea}${estacion}${vestibulo}_`uname -n`.t${count}
fi

if [[ ${debug} -eq 1 ]]; then
    print mes=${mes}, dia=${dia} l�nea=${linea} estaci�n=${estacion} vestibulo=${vestibulo}
    print Nombre de fichero: ${fname}
fi
#
# Genera un nombre temporal con el que se crea inicialmente el fichero.
#
tmpfname=/tmp/.CreaVolcado.ksh.$$

#
# Elimina de los argumentos el path si es ${path_rm}. Por si tiene wildcards
# genera en la variable path_rm_nw una versi�n sin ellos. Da por supuesto que
# es el mismo para todos los ficheros.
#
integer i=0
set -A tar_files $*
while [[  ${i} -lt $# ]]; do
    tar_file_path=${tar_files[${i}]}
    tar_files[${i}]=${tar_files[${i}]#${path_rm}}
    if [[ ${tar_file_path} != ${tar_files[${i}]} ]]; then
	path_rm_nw=${tar_file_path%${tar_files[${i}]}}
    fi
    (( i+=1 ))
done

#
# Crea el fichero temporal. La opci�n 'e' del tar es para que retorne un c�digo de
# error (solo para Solaris) en caso de haber cualquier problema.
#
if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: Creando tar de ${tar_files[*]} relativo a ${path_rm_nw}"
fi
if [[ ${debug} -eq 1 ]]; then
    if [[ i -eq 1 ]]; then
       print "${0##*/}: Creando tar de ${tar_files[0]} relativo a ${path_rm_nw} en fichero temporal: ${tmpfname}..."
       tar ecvf ${tmpfname} -C ${path_rm_nw} ${tar_files[0]} 2>&1
    else
       if [[ i -eq 2 ]]; then
          print "${0##*/}: Creando tar de ${tar_files[0]} y ${tar_files[1]} relativo a ${path_rm_nw} en fichero temporal: ${tmpfname}..."
          tar ecvf ${tmpfname} -C ${path_rm_nw} ${tar_files[0]} -C ${path_rm_nw} ${tar_files[1]} 2>&1
       else
          print "${0##*/}: Imposible empaquetar ${tar_files[*]} relativo a ${path_rm_nw}. Mas de 2 ficheros!"
          tar ecvf ${tmpfname} -C ${path_rm_nw} ${tar_files[*]} 2>&1
       fi
    fi
else
    # Esta solucion es casuistica, pero no se nos ocurre otra ByNow
    if [[ i -eq 1 ]]; then
       print >>${logfname} 2>&1 "${0##*/}: Creando tar de ${tar_files[0]} relativo a ${path_rm_nw} en fichero temporal: ${tmpfname}..."
       tar ecf ${tmpfname} -C ${path_rm_nw} ${tar_files[0]} >/dev/null 2>>${logfname}
    else
       if [[ i -eq 2 ]]; then
          print >>${logfname} 2>&1 "${0##*/}: Creando tar de ${tar_files[0]} y ${tar_files[1]} relativo a ${path_rm_nw}."
          tar ecf ${tmpfname} -C ${path_rm_nw} ${tar_files[0]} -C ${path_rm_nw} ${tar_files[1]} >/dev/null 2>>${logfname}
       else
	  print >>${logfname} 2>&1 "${0##*/}: Imposible empaquetar ${tar_files[*]} relativo a ${path_rm_nw}. Mas de 2 ficheros!."
          tar ecf ${tmpfname} -C ${path_rm_nw} ${tar_files[*]} >/dev/null 2>>${logfname}
       fi
    fi
fi
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Error en tar. Saliendo."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error en tar."
    fi
    rm -f ${tmpfname}
    exit 5
fi

#
# Comprime el fichero temporal con el gzip. Tiene en cuenta que se a�ade la
# extensi�n .gz. Usa la opci�n -f para machacar otro que haya con el mismo
# nombre.
#
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Comprimiendo fichero temporal..."
fi
gzip -f ${tmpfname} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Error en gzip. Saliendo."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error en gzip."
    fi
    rm -f ${tmpfname}
    exit 6
fi
# A�ade la extensi�n al nombre del fichero temporal.
tmpfname=${tmpfname}.gz

#
# Mueve al directorio destino el fichero creado.
#
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Moviendo fichero temporal ${tmpfname} a ${voldir}..."
fi
mv -f ${tmpfname} ${voldir} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Error en mv. Saliendo."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error en mv ${tmpfname} ${voldir}"
    fi
    rm -f ${tmpfname}
    exit 7
fi

#
# Cambia el nombre del fichero temporal para indicar que ya puede ser mandado.
# Elimina el path ya que antes hace un cd.
#
# tmpfname=$(basename ${tmpfname}) es otra posibilidad.
#
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Renombrando fichero temporal ${tmpfname##*/} a ${fname}..."
fi
cd ${voldir} >/dev/null 2>&1
mv -f ${tmpfname##*/} ${fname} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    if [[ ${debug} -eq 1 ]]; then
	print "${0##*/}: Error renombrando. Saliendo."
    fi
    if [[ ${logfile} -eq 1 ]]; then
	print >>${logfname} 2>&1 "${0##*/}: Error en mv ${tmpfname##*/} ${fname}"
    fi
    rm -f ${tmpfname##*/}
    exit 8
fi
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Creado volcado ${fname} OK."
fi
if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: Creado volcado ${fname} OK."
fi

#
# Ejecuta MandaVolcados.ksh para que si hay comunicaci�n se env�e el nuevo volcado
# inmediatamente.
#
if [[ ${test_on} -eq 1 ]]; then
    mvcmd="${HOME}/volcados/MandaVolcados.ksh"
    mvopts="-t"
else
    mvcmd="/home/metro/sun/MandaVolcados.ksh"
    mvopts=""
fi

if [[ ${logfile} -eq 1 ]]; then
    mvopts="${mvopts} -l ${logfname}"
else
    mvopts="${mvopts}"
fi

if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: Arrancando ${mvcmd} ${mvopts}"
fi
if [[ ${debug} -eq 1 ]]; then
    print "${0##*/}: Arrancando ${mvcmd} ${mvopts} -d"
fi
if [[ ${debug} -eq 1 ]]; then
    ${mvcmd} ${mvopts} -d
else
    ${mvcmd} ${mvopts} >/dev/null 2>&1 &
fi

#
# Una vez terminado regenera el fichero, incrementando el contador del proceso de hoy en uno.
#
(( lastvolnum[${lastidx}]+=1 ))
rm -f ${lastfname} 2>&1
integer i=0
while [[  ${i} -lt ${lastcount} ]]; do
    if [[ ${lastproc[${i}]} = "" ]]; then
	if [[ ${debug} -eq 1 ]]; then
	    print "A�adiendo l�nea ${lasttoday} NULL ${lastvolnum[${i}]} a ${lastfname}" 
	fi
       	print "${lasttoday} NULL ${lastvolnum[${i}]}" >>${lastfname}
    else
	if [[ ${debug} -eq 1 ]]; then
	    print "A�adiendo l�nea ${lasttoday} ${lastproc[${i}]} ${lastvolnum[${i}]} a ${lastfname}" 
	fi
	print "${lasttoday} ${lastproc[${i}]} ${lastvolnum[${i}]}" >>${lastfname}
    fi
    (( i+=1 ))
done

if [[ ${logfile} -eq 1 ]]; then
    print >>${logfname} 2>&1 "${0##*/}: `date` Fin log."
fi

exit 0

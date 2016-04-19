#!/bin/csh -f
#
# 	Distrib.csh: Sube los datos del repositorio al frontend.
#
cd /
# · Directorio de repositorio en las maquinas donde estan los tar.gz (frontends)
set voldir = $HOME/repositorio
set host = `/usr/bin/cat /etc/nodename | /usr/bin/awk '{print $1}' | sed "s/\(.*\)-\(.*\)/\1/g"`
set fecha = `date`
echo 'Comienzo de envio de datos desde '$host $fecha >> $voldir/repositorio.log
cd /home/metro/sistema/V
switch ( $host )
case vest:
case 1vest:
case vest2:
case 2vest:
case vest3:
case 3vest:
   set host_remoto = `awk '{ if ((NF == 4) && ($3 == 1)) { print $4; exit } }' CfgConfig.CFG`
   echo 'el nombre del host del pcl es '$host_remoto >> $voldir/repositorio.log
   breaksw
default:
   set host_temp = `awk ' (NF == 7 || NF == 5) && substr($4,1,5)=="front" { print $4 }' CfgConfig.CFG`
   set host_remoto = `echo $host_temp | cut -f1 -d'@'`
   echo 'el nombre del front es '$host_remoto >> $voldir/repositorio.log
   breaksw
endsw

#
# Comprueba que el directorio existe y se puede usar.
#
if ( ! -e $voldir ) then
   echo 'No existe el directorio ' $voldir >> $voldir/repositorio.log
   exit 1
endif
if ( ! -d $voldir ) then
   echo 'El directorio' $voldir ' no es valido' >> $voldir/repositorio.log
   exit 1
endif
if ( ! -x $voldir || ! -r $voldir || ! -w $voldir ) then
   echo 'el directorio ' $voldir ' no tiene los permisos adecuados' >> $voldir/repositorio.log
   exit 1
endif

#
# Comprueba que hay ficheros para enviar.
#
ls $voldir/*.tar.gz >>& $voldir/repositorio.log
if ( $status == 1 ) then
   echo 'No hay ficheros por enviar' >> $voldir/repositorio.log
   exit 1
endif  

#
# Comprueba comunicacion con la maquina remota.
#
/usr/sbin/ping $host_remoto >>& $voldir/repositorio.log
if ( $status == 1 ) then
   echo '	Sin comunicación con ' $host_remoto >> $voldir/repositorio.log
   exit 1
endif  

cd $voldir

switch ( $host )
case vest:
case 1vest:
   set vestname=vest
   breaksw
case vest2:
case 2vest:
   set vestname=vest2  
   breaksw
case vest3:
case 3vest:
   set vestname=vest3  
   breaksw
endsw

switch ( $host )
case vest:
case 1vest:
case vest2:   
case 2vest:
case vest3:
case 3vest:
   echo 'enviando el fichero del vest.....' >> $voldir/repositorio.log
   mv $voldir/$host.tar.gz $voldir/${vestname}_$host_remoto.tar.gz >>& $voldir/repositorio.log
   ls -l $voldir >>& $voldir/repositorio.log
   set tamvest = `ls -lo $voldir|grep ${vestname}_$host_remoto.tar.gz|/usr/bin/awk '{print $4}'`
   rcp -p $voldir/${vestname}_$host_remoto.tar.gz "$host_remoto":$voldir/${vestname}_$host_remoto.tmp >>& $voldir/repositorio.log
   rsh $host_remoto ls -l $voldir >>& $voldir/repositorio.log
   set tampcl = `rsh $host_remoto ls -lo $voldir|grep ${vestname}_$host_remoto.tmp|/usr/bin/awk '{print $4}'`
   if ( $tamvest == $tampcl ) then
      rsh $host_remoto mv $voldir/${vestname}_$host_remoto.tmp  $voldir/${vestname}_$host_remoto.tar.gz >>& $voldir/repositorio.log
      #rm $voldir/*.tar.gz >>& $voldir/repositorio.log
      echo "fichero del vest enviado correctamente (en $host_remoto $tampcl = a $host $tamvest)....." >> $voldir/repositorio.log
   else
      rsh $host_remoto rm $voldir/${vestname}_$host_remoto.tmp >>& $voldir/repositorio.log
      echo "ha ocurrido algun error enviando el fichero del vest (en $host_remoto $tampcl = a $host $tamvest)....." >> $voldir/repositorio.log
   endif
   breaksw
default:
   ls -l $voldir >>& $voldir/repositorio.log
   echo 'enviando el fichero del vest3.....' >> $voldir/repositorio.log 
   rcp -p $voldir/vest3_*.tar.gz "$host_remoto":$voldir >>& $voldir/repositorio.log
   #rm $voldir/vest3_*.tar.gz >>& $voldir/repositorio.log
   echo 'enviando el fichero del vest2.....' >> $voldir/repositorio.log 
   rcp -p $voldir/vest2_*.tar.gz "$host_remoto":$voldir >>& $voldir/repositorio.log
   #rm $voldir/vest2_*.tar.gz >>& $voldir/repositorio.log
   echo 'enviando el fichero del vest.....' >> $voldir/repositorio.log
   rcp -p $voldir/vest_*.tar.gz "$host_remoto":$voldir >>& $voldir/repositorio.log
   #rm $voldir/vest*.tar.gz >>& $voldir/repositorio.log
   echo 'enviando el fichero del pcl.....' >> $voldir/repositorio.log
   rcp -p $voldir/$host.tar.gz "$host_remoto":$voldir >>& $voldir/repositorio.log
   #rm $voldir/$host.tar.gz >>& $voldir/repositorio.log
   breaksw
endsw

set fecha = `date`   
echo 'Fin de envio de datos desde '$host $fecha >> $voldir/repositorio.log

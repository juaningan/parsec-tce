#!/bin/sh
#ident  "@(#)Filtrado de datos particulares 1.0     3/12/2001"
#
# Copyright: SICO software 2001
#
#
# CapturaFicheros.sh: Script que genera un fichero.tar que contiene solo los datos 
#                     particulares de cada nodo de Captura de Datos, libre de Basura.
#
#
# Historia:
#            3-Dic-01 Carlos Culebras Alejo               Codigo inicial 
#
# Por hacer:
#	     Buurrff, si yo te contara ;)
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
      
   cd /
   
   Host=`/usr/bin/cat /etc/nodename | /usr/bin/awk '{print $1}' | sed "s/\(.*\)-\(.*\)/\1/g"`
   voldir=/home/metro/repositorio
   fecha=`date`
   
   #
   # Comprueba que el directorio existe y se puede usar.
   #   
   if [ ! -d $voldir ]; then
   	/usr/bin/rm -rf $voldir
	/usr/bin/mkdir $voldir
	/usr/bin/chmod 777 $voldir
	/usr/bin/chown metro $voldir   	
   fi
   if [ ! -x $voldir ] || [ ! -r $voldir ] || [ ! -w $voldir ]; then   	
	/usr/bin/chmod 777 $voldir
	/usr/bin/chown metro $voldir   	
   fi
      
   echo "${fecha} Comienza proceso de recopilacion de datos en ${Host}" > $voldir/repositorio.log
   echo "ficheros exluidos del tar :" >> $voldir/repositorio.log
        
   # Si el fichero no existe, y comando ls devuelve error ,
   # no pasa nada porque no se escribe el error en Excluidos
   ls -1d home/metro/sistema/V/core > Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/core >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/core >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.Z >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/*/*.Z >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/*/*/*.Z >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.tar >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/*/*.tar >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.tar >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/kk >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/kk >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/kk >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*Log* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.OLD >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.OLD >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.OLD >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.old >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.old >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.old >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.tmp >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.tmp >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.tmp >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.TMP >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.TMP >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.TMP >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/x* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/x* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/x* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.gz >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.gz >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.gz >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.query* >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/*/*.query* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.query* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.SAV >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.SAV >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.SAV >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.sav >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*.sav >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*.sav >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/*% >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*% >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*/*/*% >> Excluidos 1>> $voldir/repositorio.log 2>&1
   
   ls -1d home/metro/sistema/V/Acciones.TXT >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/*.Now >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Dummy* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Alarmas.txt >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Acciones.txt >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/AlarmasSel.CA >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/ListaProcesos >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/SicoLibreria.icon >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Agentes.txt >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/FichEstaciones >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/CfgTipoEq.CFG >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/CfgRouter.CFG >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/CfgSubs2.CFG >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/StrDrivers.CFG >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Alarmas.def >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Manten.cod >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Agente.cod >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Programacion.* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/tempalarm >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/PARAM_SW.DAT >> Excluidos 1>> $voldir/repositorio.log 2>&1
   
   
   ls -1d home/metro/sistema/V/Ascensor/xEventos* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/bitmaps >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Buzon >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Cancela >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/CtrlAcc >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/CtrlInst >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/CtrlPcl >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Config >> Excluidos 1>> $voldir/repositorio.log 2>&1 
   ls -1d home/metro/sistema/V/DisplayPCL/* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/EstadoRT >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Escalera/* >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Mbt >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Metta >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Newsai >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Newsai2 >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/plano >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Porton >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Pupitre >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Sound >> Excluidos 1>> $voldir/repositorio.log 2>&1   
   ls -1d home/metro/sistema/V/Telefonia >> Excluidos 1>> $voldir/repositorio.log 2>&1
   ls -1d home/metro/sistema/V/Volcados >> Excluidos 1>> $voldir/repositorio.log 2>&1


   # Se hace un tar Relativo usando el fichero con los excluidos
   # Ojo NO Absoluto, para poder extraer todos en un cierto directorio

	/usr/sbin/tar cvfX /tmp/$Host.tar Excluidos etc/nodename etc/net/*/hosts etc/inet/hosts etc/inet/networks etc/inet/netmasks \
   		        etc/init.d/ppp etc/init.d/ppp.cfg etc/*.d/K47ppp etc/rc2.d/S47ppp  etc/ppp/peers/* etc/hostname.* etc/defaultrouter \
   		        var/spool/cron/crontabs/metro var/spool/cron/crontabs/root dev/ttys* dev/ttyS2 \
   		        etc/inet/services \
			opt/bin/*.dat \
			usr/local/tce/tce \
			home/metro/.ssh/authorized_keys \
   		        home/metro/sistema/V/Cfg*.CFG \			
   		 	home/metro/sistema/V/Ascensor/*.CFG 1>> $voldir/repositorio.log 2>&1
   		 	
	/usr/sbin/tar uvf /tmp/$Host.tar home/metro/sistema/V/Metta/METT*/xFichParaIndra home/metro/sistema/V/Newsai2/FichTiposEventos \
                     home/metro/sistema/V/Metta/CfgMetta2000.CFG \
         	     home/metro/sistema/V/Metta/CfgMettaEuro.CFG \
		     home/metro/sistema/V/Ascensor/*.CFG \
         	     home/metro/sistema/V/AntiIntrusion/FichConfig* \
   		     home/metro/sistema/V/Newsai2/SAI0000/Config.NEWSAI2 home/metro/sistema/V/Metta/CorresPago.CFG \
   		     home/metro/sistema/V/Mbt/MBT* home/metro/sistema/V/CtrlAcc/ACC*/xFichParaProsotec \
  		     home/metro/sistema/V/CtrlPcl/PCL*/*.CFG home/metro/sistema/V/CtrlPcl/PCL*/*.conf \
  		     home/metro/sistema/V/CtrlPcl/PCL*/*.bin home/metro/sistema/V/CtrlPcl/PCL*/Programaciones \
		     home/metro/sistema/V/Porton/POR*/CfgPorton.CFG \
		     home/metro/sistema/V/Pupitre/PupitreConf.CFG \
		     home/metro/sistema/V/UI_Plano/ui_concentrador/CfgIsaCD.CFG \
		     home/metro/sistema/V/Pupitre/PPT*/*.CFG \
   		     home/metro/sistema/V/Telefonia/CfgTelefonia.CFG \
   		     home/metro/sistema/V/Emergencia/EME*/*.CFG \
   		     home/metro/sistema/V/CtrlInst/PCL*/Datos.CFG home/metro/sistema/V/CtrlInst/PCL*/h1_0.dat \
  		     home/metro/sistema/V/Cancela/CAN*/Datos.CFG home/metro/sistema/V/Cancela/CAN*/h1_0.dat \
  		     home/metro/sistema/V/Cancela/CAN*/Instancias.dat \
  		     home/metro/sistema/V/CancelaTunel/CCT*/h1_0.dat \
  		     home/metro/sistema/V/CancelaTunel/CCT*/CfgInstancias.CFG \
  		     home/metro/sistema/V/CancelaTunel/CCT*/CfgParametros.CFG \
  		     home/metro/sistema/V/Programador/PRO*/Ascensores.dat \
  		     home/metro/sistema/V/Programador/PRO*/Instancias.dat \
  		     home/metro/sistema/V/Programador/PRO*/Datos.CFG \
		     home/metro/sistema/V/AireAcond/AIR*/Config.DISP.AIRE \
		     home/metro/sistema/V/AireAcond/Config.AIREACOND \
		     home/metro/sistema/V/CajaDotacion/Config.CAJADOTACION \
		     home/metro/sistema/V/Alumbrado/CfgUIAlumbrado.CFG \
		     home/metro/sistema/V/AlumbradoTunel/ConfigAlum*.CFG \
		     home/metro/sistema/V/Ventilacion/CfgUIVent.CFG \
		     home/metro/sistema/V/Ventilacion/CfgVentilacion.CFG \
		     home/metro/sistema/V/Ventilacion/ConfigVent_*.CFG \
		     home/metro/sistema/V/PozosBombeo/*.CFG \
		     home/metro/sistema/V/Pozos/*.CFG \
		     home/metro/sistema/V/CtrlPcl/AlarmasPozos \
		     home/metro/sistema/V/CtrlMegaf/MGF*/*.CFG \
		     home/metro/sistema/V/CtrlEmergencia/CEM*/*.CFG \
		     home/metro/sistema/V/Mensaje* \
		     home/metro/sistema/V/*icons \
		     home/metro/sistema/V/*Raster \
		     home/metro/sistema/V/*xpm \
		     home/metro/sistema/V/*FichTextos* \
		     home/metro/sistema/V/*FichIconosEstacion \
		     home/metro/sistema/V/*FichPlanoEstacion \
		     home/metro/sistema/V/pru-bea.sh \
		     home/metro/.autostart home/metro/.login home/metro/.cshrc home/metro/.autoarranque \
		     home/metro/sistema/V/CfgAlarmasUrgentes.CFG home/metro/sistema/V/fSubsistemas 1>> $voldir/repositorio.log 2>&1

  
  # Se comprime el tar
  /usr/local/bin/gzip /tmp/$Host.tar 1>> $voldir/repositorio.log 2>&1
  /usr/bin/rm Excluidos 1>> $voldir/repositorio.log 2>&1
  /usr/bin/chown metro /tmp/$Host.tar.gz 1>> $voldir/repositorio.log 2>&1
  /usr/bin/chmod 666 /tmp/$Host.tar.gz 1>> $voldir/repositorio.log 2>&1 
  /usr/bin/rm $voldir/*.tar.gz 1>> $voldir/repositorio.log 2>&1
  /usr/bin/mv /tmp/$Host.tar.gz $voldir 1>> $voldir/repositorio.log 2>&1
  
  fecha=`date`  
  echo "${fecha} Fin proceso de recopilacion de datos en ${Host}" >> $voldir/repositorio.log 2>&1
  
  /usr/bin/chown metro $voldir/repositorio.log 2>&1
  /usr/bin/chmod 666 $voldir/repositorio.log 2>&1 

#!/bin/csh -f

set Nom_volcado = $1
echo " - TratarVolcado $Nom_volcado"

set Juliano = `echo $Nom_volcado | awk '{ print substr($Nom_volcado,13,3) }'`

echo " - Descompresion para Jornada $Juliano"

mkdir $Juliano
cd $Juliano
cp ../$Nom_volcado .
tar xvf $Nom_volcado
echo " - Borramos $Nom_volcado del directorio del tar"
rm $Nom_volcado
cd ..
/usr/local/bin/gzip $Nom_volcado
echo " - Guardo el $Nom_volcado en Enviados"
set Nom_gz = $Nom_volcado".gz"
mv $Nom_gz ../Enviados


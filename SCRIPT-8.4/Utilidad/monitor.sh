#!/bin/bash
ll="/usr/local/include/snaps" && [[ ! -d ${ll} ]] && exit
l="/usr/local/lib/sped" && [[ ! -d ${l} ]] && exit
# Directorio destino
DIR=/var/www/html

# Nombre de archivo HTML a generar
ARCHIVO=monitor.html

# Fecha actual
FECHA=$(date +'%d/%m/%Y %H:%M:%S')

# Declaraci\303\263n de la funci\303\263n
EstadoServicio() {

	systemctl --quiet is-active $1
	if [ $? -eq 0 ]; then
		echo "<p>Estado del servicio $1 est\303\241 || <span class='encendido'> ACTIVO</span>.</p>" >>$DIR/$ARCHIVO
	else
		echo "<p>Estado del servicio $1 est\303\241 || <span class='detenido'> DESACTIVADO | REINICIANDO</span>.</p>" >>$DIR/$ARCHIVO
		service $1 restart &
		NOM=$(less /etc/VPS-MX/controlador/nombre.log) >/dev/null 2>&1
		NOM1=$(echo $NOM) >/dev/null 2>&1
		IDB=$(less /etc/VPS-MX/controlador/IDT.log) >/dev/null 2>&1
		IDB1=$(echo $IDB) >/dev/null 2>&1
		KEY="xxxxxx"
		URL="https://api.telegram.org/bot$KEY/sendMessage"
		MSG="\342\232\240\357\270\217 _AVISO DE VPS:_ *$NOM1* \342\232\240\357\270\217\342\235\227\357\270\217 _Protocolo_ *[ $1 ]* _con Fallo_ \342\235\227\357\270\217 \360\237\233\240 _-- Reiniciando Protocolo_ -- \360\237\233\240 "
		# curl -s --max-time 10 -d "chat_id=$IDB1&disable_web_page_preview=true&parse_mode=markdown&text=$MSG" $URL
	fi
}

# Comienzo de la generaci\303\263n del archivo HTML
# Esta primera parte constitute el esqueleto b\303\241sico del mismo.
echo "
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <meta http-equiv='X-UA-Compatible' content='ie=edge'>
  <title>Monitor de Servicios LACASITAMX</title>
  <link rel='stylesheet' href='estilos.css'>
</head>
<body>
<h1>Monitor de Servicios @LaCasitaMx_Noty_Bot</h1>
<p id='ultact'>\303\232ltima actualizaci\303\263n: $FECHA</p>
<hr>
" >$DIR/$ARCHIVO
# Servicios a chequear (podemos agregar todos los que deseemos

# PROTOCOLO v2ray
EstadoServicio v2ray
# PROTOCOLO SSH
EstadoServicio ssh
# PROTOCOLO DROPBEAR
EstadoServicio dropbear
# PROTOCOLO SSL
EstadoServicio stunnel4
# PROTOCOLOSQUID
[[ $(EstadoServicio squid) ]] && EstadoServicio squid3
# PROTOCOLO APACHE
EstadoServicio apache2
on="<span class='encendido'> ACTIVO " && off="<span class='detenido'> DESACTIVADO | REINICIANDO "
[[ $(ps x | grep badvpn | grep -v grep | awk '{print $1}') ]] && badvpn=$on || badvpn=$off
echo "<p>Estado del servicio badvpn est\303\241 ||  $badvpn </span>.</p> " >>$DIR/$ARCHIVO

#SERVICE BADVPN
PIDVRF3="$(ps aux | grep badvpn | grep -v grep | awk '{print $2}')"
if [[ -z $PIDVRF3 ]]; then
	screen -dmS badvpn2 /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
	NOM=$(less /etc/VPS-MX/controlador/nombre.log) >/dev/null 2>&1
	NOM1=$(echo $NOM) >/dev/null 2>&1
	IDB=$(less /etc/VPS-MX/controlador/IDT.log) >/dev/null 2>&1
	IDB1=$(echo $IDB) >/dev/null 2>&1
	KEY="xxxxxx"
	URL="https://api.telegram.org/bot$KEY/sendMessage"
	MSG="\342\232\240\357\270\217 _AVISO DE VPS:_ *$NOM1* \342\232\240\357\270\217\342\235\227\357\270\217 _Protocolo_ *[ BADVPN ]* _con Fallo_ \342\235\227\357\270\217 \360\237\233\240 _-- Reiniciando Protocolo_ -- \360\237\233\240 "
	# curl -s --max-time 10 -d "chat_id=$IDB1&disable_web_page_preview=true&parse_mode=markdown&text=$MSG" $URL
else
	for pid in $(echo $PIDVRF3); do
		echo ""
	done
fi

#SERVICE PYTHON DIREC
ureset_python() {
	for port in $(cat /etc/VPS-MX/PortPD.log | grep -v "nobody" | cut -d' ' -f1); do
		PIDVRF3="$(ps aux | grep pydic-"$port" | grep -v grep | awk '{print $2}')"
		if [[ -z $PIDVRF3 ]]; then
			screen -dmS pydic-"$port" python /etc/VPS-MX/protocolos/python.py "$port"
			NOM=$(less /etc/VPS-MX/controlador/nombre.log) >/dev/null 2>&1
			NOM1=$(echo $NOM) >/dev/null 2>&1
			IDB=$(less /etc/VPS-MX/controlador/IDT.log) >/dev/null 2>&1
			IDB1=$(echo $IDB) >/dev/null 2>&1
			KEY="xxxxxx"
			URL="https://api.telegram.org/bot$KEY/sendMessage"
			MSG="\342\232\240\357\270\217 _AVISO DE VPS:_ *$NOM1* \342\232\240\357\270\217\342\235\227\357\270\217 _Protocolo_ *[ PyDirec: $port ]* _con Fallo_ \342\235\227\357\270\217 \360\237\233\240 _-- Reiniciando Protocolo_ -- \360\237\233\240 "
			# curl -s --max-time 10 -d "chat_id=$IDB1&disable_web_page_preview=true&parse_mode=markdown&text=$MSG" $URL
		else
			for pid in $(echo $PIDVRF3); do
				echo ""
			done
		fi
	done
}

#SERVICE PY+SSL

ureset_pyssl() {
	for port in $(cat /etc/VPS-MX/PySSL.log | grep -v "nobody" | cut -d' ' -f1); do
		PIDVRF3="$(ps aux | grep pyssl-"$port" | grep -v grep | awk '{print $2}')"
		if [[ -z $PIDVRF3 ]]; then
			screen -dmS pyssl-"$port" python /etc/VPS-MX/protocolos/python.py "$port"
			NOM=$(less /etc/VPS-MX/controlador/nombre.log) >/dev/null 2>&1
			NOM1=$(echo $NOM) >/dev/null 2>&1
			IDB=$(less /etc/VPS-MX/controlador/IDT.log) >/dev/null 2>&1
			IDB1=$(echo $IDB) >/dev/null 2>&1
			KEY="xxxxxx"
			URL="https://api.telegram.org/bot$KEY/sendMessage"
			MSG="\342\232\240\357\270\217 _AVISO DE VPS:_ *$NOM1* \342\232\240\357\270\217\342\235\227\357\270\217 _Protocolo_ *[ PyDirec: $port ]* _con Fallo_ \342\235\227\357\270\217 \360\237\233\240 _-- Reiniciando Protocolo_ -- \360\237\233\240 "
			# curl -s --max-time 10 -d "chat_id=$IDB1&disable_web_page_preview=true&parse_mode=markdown&text=$MSG" $URL
		else
			for pid in $(echo $PIDVRF3); do
				echo ""
			done
		fi
	done
}

ureset_python
ureset_pyssl

pidproxy3=$(ps x | grep -w "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy3 ]] && P3="<span class='encendido'> ACTIVO " || P3="<span class='detenido'> DESACTIVADO | REINICIANDO "
echo "<p>Estado del servicio PythonPort est\303\241 ||  $P3 </span>.</p> " >>$DIR/$ARCHIVO
#LIBERAR RAM,CACHE
#sync ; echo 3 > /proc/sys/vm/drop_caches ; echo "RAM Liberada"
# Finalmente, terminamos de escribir el archivo
echo "
</body>
</html>" >>$DIR/$ARCHIVO

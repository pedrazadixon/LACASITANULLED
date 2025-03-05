#!/bin/bash
ll="/usr/local/include/snaps" && [[ ! -d ${ll} ]] && exit
l="/usr/local/lib/sped" && [[ ! -d ${l} ]] && exit
#by @rufu99
[[ ! -d /etc/VPS-MX ]] && exit
[[ ! -d /etc/VPS-MX/protocolos ]] && exit
ADM_inst="/etc/VPS-MX/Slow/install" && [[ ! -d ${ADM_inst} ]] && exit
ADM_slow="/etc/VPS-MX/Slow/Key" && [[ ! -d ${ADM_slow} ]] && exit
info() {
	clear
	nodata() {
		msg -bar
		msg -ama "!SIN INFORMACION SLOWDNS!"
		exit 0
	}

	if [[ -e ${ADM_slow}/domain_ns ]]; then
		ns=$(cat ${ADM_slow}/domain_ns)
		if [[ -z "$ns" ]]; then
			nodata
			exit 0
		fi
	else
		nodata
		exit 0
	fi

	if [[ -e ${ADM_slow}/server.pub ]]; then
		key=$(cat ${ADM_slow}/server.pub)
		if [[ -z "$key" ]]; then
			nodata
			exit 0
		fi
	else
		nodata
		exit 0
	fi

	msg -bar
	msg -ama "\\e[97m DATOS DE SU CONEXION SLOWDNS"
	msg -bar
	msg -ama "   Su NS (Nameserver): \\e[92m$(cat ${ADM_slow}/domain_ns)"
	msg -bar
	msg -ama "   Su Llave: \\e[92m$(cat ${ADM_slow}/server.pub)"
	msg -bar
	exit 0
}

drop_port() {
	local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
	local NOREPEAT
	local reQ
	local Port
	unset DPB
	while read port; do
		reQ=$(echo ${port} | awk '{print $1}')
		Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
		[[ $(echo -e $NOREPEAT | grep -w "$Port") ]] && continue
		NOREPEAT+="$Port\\n"

		case ${reQ} in
		sshd | dropbear | trojan | stunnel4 | stunnel | python | python3 | v2ray | xray) DPB+=" $reQ:$Port" ;;
		*) continue ;;
		esac
	done <<<"${portasVAR}"
}

ini_slow() {
	clear
	msg -bar
	msg -ama "    INSTALADOR SLOWDNS"
	msg -bar
	echo ""
	drop_port
	n=1
	for i in $DPB; do
		proto=$(echo $i | awk -F ":" '{print $1}')
		proto2=$(printf '%-12s' "$proto")
		port=$(echo $i | awk -F ":" '{print $2}')
		echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
		drop[$n]=$port
		dPROT[$n]=$proto2
		num_opc="$n"
		let n++
	done
	msg -bar
	opc=$(selection_fun $num_opc)
	echo "${drop[$opc]}" >${ADM_slow}/puerto
	echo "${dPROT[$opc]}" >${ADM_slow}/puertoloc
	PORT=$(cat ${ADM_slow}/puerto)
	clear
	msg -bar
	msg -ama "  INSTALADOR SLOWDNS"
	msg -bar
	echo ""
	echo -e " $(msg -ama "Puerto de conexion atraves de SlowDNS:") $(msg -verd "$PORT")"
	msg -bar

	[[ -e ${ADM_slow}/domain_ns ]] && NS1=$(cat <${ADM_slow}/domain_ns) || unset NS1 NS
	unset NS
	[[ -z $NS1 ]] && {
		while [[ -z $NS ]]; do
			msg -bar
			echo -ne "\\e[1;31m INGRESAR DOMINIO NS \\e[1;37m: "
			read NS
			tput cuu1 && tput dl1
		done
	} || {
		msg -bar
		echo -e "\\e[1;33m      TIENES UN DOMINIO NS YA REGISTRADO \\e[1;37m "
		echo -e "\\e[1;97m   TU NS ES : ${NS1} \\e[1;33m "
		echo -e "  SI QUIERES UTILIZARLO EL MISMO DOMINIO SOLO PRECIONA ENTER"
		echo -e "       EN CASO CONTRARIO DIJITE SU NUEVO NS "
		msg -bar
		echo -ne "\\e[1;31m TU DOMINIO NS \\e[1;37m: "
		read NS
		[[ -z $NS ]] && NS="${NS1}"
		tput cuu1 && tput dl1
		echo "$NS" >${ADM_slow}/domain_ns
	}
	echo "$NS" >${ADM_slow}/domain_ns
	echo -e " $(msg -ama "NAME SERVER:") $(msg -verd "$NS")"
	msg -bar

	if [[ ! -e ${ADM_inst}/dns-server ]]; then
		msg -ama " Descargando binario...."
		if wget -O ${ADM_inst}/dns-server https://raw.githubusercontent.com/pedrazadixon/LACASITANULLED/main/SCRIPTMOD/SLOWDNS/dns-server &>/dev/null; then
			chmod +x ${ADM_inst}/dns-server
			msg -verd " DESCARGA CON EXITO"
		else
			msg -verm " DESCARGA FALLIDA"
			msg -bar
			msg -ama "No se pudo descargar el binario"
			msg -verm "Instalacion cancelada"

			exit 0
		fi
		msg -bar
	fi

	[[ -e "${ADM_slow}/server.pub" ]] && pub=$(cat ${ADM_slow}/server.pub)

	if [[ ! -z "$pub" ]]; then
		msg -ama " Usar La clave existente [S/N] ?: "
		read ex_key

		case $ex_key in
		s | S | y | Y)
			tput cuu1 && tput dl1
			echo -e " $(msg -ama "Tu clave:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")"
			;;
		n | N)
			tput cuu1 && tput dl1
			rm -rf ${ADM_slow}/server.key
			rm -rf ${ADM_slow}/server.pub
			${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
			echo -e " $(msg -ama "Tu clave:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")"
			;;
		*) ;;
		esac
	else
		rm -rf ${ADM_slow}/server.key
		rm -rf ${ADM_slow}/server.pub
		${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
		echo -e " $(msg -ama "Tu clave:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")"
	fi
	msg -bar
	msg -ama "    INSTALANDO SERVICIO \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216   ..."
	apt install ncurses-utils -y &>/dev/null
	apt-get install iptables -y &>/dev/null

	iptables -I INPUT -p udp --dport 5300 -j ACCEPT
	iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300

	sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/g' /etc/ssh/sshd_config
	echo "[Unit]
Description=Slowdns by @lacasitamx
Documentation=SlowDNS Server
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT
Restart=always
RestartSec=3s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target" >/etc/systemd/system/slowserver.service
	chmod +x /etc/systemd/system/slowserver.service
	systemctl daemon-reload
	systemctl enable slowserver
	systemctl start slowserver
	systemctl restart slowserver

	msg -verd " INSTALACION CON EXITO"
	exit 0
}

reset_slow() {
	clear
	msg -bar
	msg -verd "    Reiniciando \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216...."

	NS=$(cat ${ADM_slow}/domain_ns)
	PORT=$(cat ${ADM_slow}/puerto)

	if [[ -e /etc/systemd/system/slowserver.service ]]; then
		systemctl daemon-reload
		systemctl restart slowserver
		msg -verd " SERVICIO SLOW REINICIADO"
	else
		msg -verm " SERVICIO NO INSTALADO"
	fi

	exit 0
}
start_slow() {
	clear
	msg -bar
	msg -verd "    INICIANDO NUEVAMEMTE EL SERVICIO \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216...."

	NS=$(cat ${ADM_slow}/domain_ns)
	PORT=$(cat ${ADM_slow}/puerto)

	if [[ -e /etc/systemd/system/slowserver.service ]]; then
		systemctl daemon-reload
		systemctl start slowserver
		systemctl restart slowserver
		msg -verd " SERVICIO SLOW REINICIADO"
	else
		msg -verm " SERVICIO NO INSTALADO"
	fi

	exit 0
}
stop_slow() {
	clear
	msg -bar
	msg -ama "    Deteniendo SlowDNS...."
	if [[ -e /etc/systemd/system/slowserver.service ]]; then
		systemctl daemon-reload
		systemctl stop slowserver

		msg -verd " SERVICIO SLOW DETENIDO!!"
	else
		msg -verm " SERVICIO SLOW NO INSTALADO"
	fi
	exit 0
}
unis_slow() {
	clear
	msg -bar
	msg -ama "    Deteniendo SlowDNS...."
	if [[ -e /etc/systemd/system/slowserver.service ]]; then
		systemctl daemon-reload
		systemctl stop slowserver
		rm -rf /etc/systemd/system/slowserver.service
		rm -rf ${ADM_slow}/server.key
		rm -rf ${ADM_slow}/server.pub
		rm -rf ${ADM_slow}/puerto*
		rm -rf ${ADM_inst}/dns-server
		msg -verd " SERVICIO SLOW DETENIDO!!"
	else
		msg -verm " SERVICIO SLOW NO INSTALADO"
	fi
	exit 0
}
portdns() {
	proto="dns-serve"
	portas=$(lsof -V -i -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND")
	for list in $proto; do
		case $list in
		dns-serve)
			portas2=$(echo $portas | grep -w "$list")
			[[ $(echo "${portas2}" | grep "$list") ]] && inst[$list]="\\033[1;33m[\\e[1;92mActivo\\e[33m] " || inst[$list]="\\033[1;33m[\\e[1;91mDesactivado\\e[1;33m]"
			;;
		esac
	done
}
while :; do
	clear
	portdns
	msg -tit
	echo ""
    if [[ -e ${ADM_slow}/puertoloc ]]; then LOC=$((cat ${ADM_slow}/puertoloc)|cut -d' ' -f1); else LOC="XX"; fi
    if [[ -e ${ADM_slow}/puerto ]]; then PT=$((cat ${ADM_slow}/puerto)|cut -d' ' -f1); else PT="XX"; fi
	msg -bar
	msg -ama "    \\e[91m\\e[43mMEN\303\232 DE INSTALACION \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216   \\e[0m"
	echo ""

	echo -e "     \\e[91mSlowDNS\\e[93m + \\e[92m${LOC} \\e[97m\302\273\302\273 \\e[91m${PT} \\e[1;97mSERVICIO: ${inst[dns - serv]}\\e[0m"
	msg -bar

	echo -e "  $(msg -verd "[1]")$(msg -verm2 "\342\236\233 ")$(msg -azu "\\e[1;92mINSTALAR \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216  ")"
	echo -e "  $(msg -verd "[2]")$(msg -verm2 "\342\236\233 ")$(msg -azu "\\e[91mDETENER \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216  ")"
	echo -e "  $(msg -verd "[3]")$(msg -verm2 "\342\236\233 ")$(msg -azu "\\e[1;92mINICIAR \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216  ")"
	echo -e "  $(msg -verd "[4]")$(msg -verm2 "\342\236\233 ")$(msg -azu "DATOS DE LA CUENTA")"
	echo -e "  $(msg -verd "[5]")$(msg -verm2 "\342\236\233 ")$(msg -azu "\\e[1;91mDESINSTALAR \360\235\231\216\360\235\231\207\360\235\231\212\360\235\231\222\360\235\230\277\360\235\231\211\360\235\231\216  ")"
	echo -e "  $(msg -verd "[0]")$(msg -verm2 "\342\236\233 ")$(msg -azu "VOLVER")"
	msg -bar
	echo -ne "  \\033[1;37mSelecione Una Opcion : "
	read opc
	case $opc in
	1) ini_slow ;;
	2) stop_slow ;;
	3) start_slow ;;
	4) info ;;
	5) unis_slow ;;
	0) exit ;;
	esac

done

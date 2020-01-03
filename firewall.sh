### Set PATH ###
IPT=/sbin/iptables
WGET=/usr/bin/wget
EGREP=/bin/egrep
TAR=/bin/tar
RM=/bin/rm

### File download ###
SPAMLIST="countrydrop"
ZONEROOT="$HOME/iptables"
DLROOT="https://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz" #only ipv4
FILE="$ZONEROOT/tmp.tar.gz"

### Clean up ###
cleanOldRules(){
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT
}
 
# create a dir
[ ! -d $ZONEROOT ] && /bin/mkdir -p $ZONEROOT
# download all zones, unzip and remove
$WGET $DLROOT -O $FILE && $TAR xvzf $FILE -C $ZONEROOT && $RM $FILE

cleanOldRules


echo
echo
echo "INIT DROPPING"
echo
echo



# create a new iptables list 
for filezone in $ZONEROOT/*
do	
	#local zone file
	if [ "$filezone" = "$ZONEROOT/us.zone" ];
	then
		SPAMLIST_ZONE="$(basename "$filezone")"
		$IPT -N $SPAMLIST_ZONE
		BADIPS=$(egrep -v "^#|^$" $filezone)
		count=1
		for ipblock in $BADIPS
		do	
			#$IPT -A $SPAMLIST_ZONE -s $ipblock -j LOG --log-prefix "$SPAMDROPMSG"
			$IPT -A $SPAMLIST_ZONE -s $ipblock -j DROP
			echo "$count) added $ipblock"
			count=$((count + 1))
		done	
		# Drop everything 
		$IPT -I INPUT -j $SPAMLIST_ZONE
		$IPT -I OUTPUT -j $SPAMLIST_ZONE
		$IPT -I FORWARD -j $SPAMLIST_ZONE
	fi

done

# call other iptable script
exit 0

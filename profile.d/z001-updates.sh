#!/bin/bash

# This entire process runs in a subshell, so we can 'exit' out of it.
(

# If this machine isn't activated, don't bother trying to
# manage the updates. Just exit quietly.

if [ ! -e /etc/sangoma/schmooze.zl -a ! -e /etc/sangoma/sangoma.zl ]; then
	exit 0
fi

# If there is no TERM variable, abort.
if [ ! "$TERM" -o "$TERM" == "dumb" ]; then
	exit 0
fi

WIDTH=60

BOLD=$(tput bold; tput smul)
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)

#BOX="unicode"

function isare() {
	if [ "$1" -eq 1 ]; then
		echo "is"
	else
		echo "are"
	fi
}

function plural() {
	if [ "$1" -eq 1 ]; then
		echo ""
	else
		echo "s"
	fi
}

function getlock() {
	eval "exec 50>/var/lock/update.lock"
	flock -n 50 && return 0 || return 1
}

function update_metadata() {
	FORCE=$1

	# If we're not root, don't bother.
	[ "$(/usr/bin/id -u)" != "0" ] && return

	# Get a lock, so we're the only one updating.
	getlock || return 

	# This should ALWAYS exist...
	mkdir -p /var/cache
	touch /var/cache/listonline
	chmod  644 /var/cache/listonline
	touch /var/cache/check-update
	chmod  644 /var/cache/check-update

	( ( exec < /dev/null
	  exec > /dev/null
	  exec 2> /dev/null
	  exec setsid bash -c "/usr/sbin/fwconsole ma listonline > /var/cache/listonline.new 2>&1; \
		rm -f /var/cache/listonline; \
		mv /var/cache/listonline.new /var/cache/listonline; \
		chmod  644 /var/cache/listonline; \
		if [ "$FORCE" ]; then yum makecache > /dev/null 2>/dev/null; fi; \
		yum -q check-update | awk 'NF' > /var/cache/check-update.new; \
		rm -f /var/cache/check-update; \
		mv /var/cache/check-update.new /var/cache/check-update; \
		chmod  644 /var/cache/check-update" < /dev/null
	) & )
}

function get_cacheage() {
	# -s = is not zero sized. So ! -s is 'is zero sized'.
	COOKIEFILE=$(ls -t /var/cache/yum/x86_64/*/sng-pkgs/cachecookie 2>/dev/null | head -1)

	if [ ! -s /var/cache/listonline -o ! "$COOKIEFILE" ]; then
		update_metadata force
		echo "ERROR"
		return
	fi
	S=$(stat -c '%Y' "$COOKIEFILE")
	echo $(( $(date '+%s') - $S ))
	return
}


function show_updates() {
	AGE=$(get_cacheage)
	if [ "$AGE" == "ERROR" ]; then
		# This has already triggered a metadata update
		centbox "No System update information available, please try later"
		return
	fi
	if [ "$AGE" -gt 86400  ]; then
		update_metadata force
	elif [ "$AGE" -gt 3600 ]; then
		update_metadata
	fi

	system_updates
	pbx_updates
}

function system_updates() {
	UPDATES=$(wc -l /var/cache/check-update 2>/dev/null | awk ' { print $1 }')
	if [ ! "$UPDATES" ]; then
		centbox "No System update information available."
		return
	fi

	if [ "$UPDATES" -eq 0 ]; then
		boxecho "${GREEN}Your system is currently up to date!${NORMAL}" $(( ${#GREEN} + ${#NORMAL} ))
	else
		boxecho "${YELLOW}There $(isare $UPDATES) ${RED}$UPDATES${YELLOW} System update$(plural $UPDATES) available.${NORMAL}" $(( ${#YELLOW} * 2 + ${#RED} + ${#NORMAL} ))
		boxecho "  Run ${BOLD}yum update${NORMAL} to update them." $(( ${#BOLD} + ${#NORMAL} ))
	fi
}


function pbx_updates() {
	# The last line will allways have a bunch of -'s on it. If it doesn't,
	# there's a problem
	LASTLINE=$(tail -1 /var/cache/listonline)
	if [[ "$LASTLINE" != *"----------"* ]]; then
		boxecho "No PBX Module updates information available"
		return
	fi

	# Do we have any BROKEN Modules?
	BROKEN=$(grep '| Broken' /var/cache/listonline | wc -l) 
	NOTINSTALLED=$(grep '| Not Installed' /var/cache/listonline | wc -l)
	UPGRADEAVAIL=$(grep '| Online upgrade available' /var/cache/listonline | wc -l)
	DISABLED=$(grep '| Disabled' /var/cache/listonline | wc -l)
	if [ "$UPGRADEAVAIL" -eq 0 ]; then
		boxecho "${GREEN}Your PBX is up to date.${NORMAL}" $(( ${#GREEN} + ${#NORMAL} ))
	else
		boxecho "${YELLOW}There $(isare $UPGRADEAVAIL) ${RED}$UPGRADEAVAIL${YELLOW} PBX module$(plural $UPGRADEAVAIL) updates available.${NORMAL}" $(( ${#YELLOW} * 2 + ${#RED} + ${#NORMAL} ))
	fi

	if [ "$DISABLED" -ne 0 ]; then
		DIS="$DISABLED Disabled module$(plural $DISABLED)"
	else
		DIS=""
	fi

	if [ "$NOTINSTALLED" -ne 0 ]; then
		NI="$NOTINSTALLED Uninstalled module$(plural $NOTINSTALLED)"
	else
		NI=""
	fi

	if [ "$DIS" -a "$NI" ]; then
		boxecho "  Also ${DIS} and ${NI}."
	elif [ "$DIS" ]; then
		boxecho "  Also ${DIS}."
	elif [ "$NI" ]; then
		boxecho "  Also ${NI}."
	fi

	if [ "$BROKEN" -ne 0 ]; then
		centbox "${BOLD}Warning: There $(isare $BROKEN) $BROKEN Broken module$(plural $BROKEN)!${NORMAL}" $(( ${#BOLD} + ${#NORMAL} ))
	fi
}

function boxecho() {
	LINE="$1"
	ANSIPADDING="$2"
	PADDING=$(( ${WIDTH} - ${#LINE} - 1 ))
	if [ "$ANSIPADDING" ]; then
		PADDING=$(( $PADDING + $ANSIPADDING ))
	fi

	if [ "$PADDING" -lt 0 ]; then
		PADDING=0
	fi
	if [ "$BOX" == "unicode" ]; then
		echo -e "┃ $LINE$(eval printf "%.0s\ " {1..$PADDING})┃"
	else
		echo -e "| $LINE$(eval printf "%.0s\ " {1..$PADDING})|"
	fi
}

function centbox() {
	LINE="$1"
	ANSIPADDING="$2"
	if [ ! "$ANSIPADDING" ]; then
		ANSIPADDING=0
	fi
	LEFTPAD=$(( ( ${WIDTH} - 1 - ${#LINE} - ${ANSIPADDING}  ) / 2 ))
	if [ $ANSIPADDING -gt 1 ]; then
		LEFTPAD=$(( $LEFTPAD - ( $ANSIPADDING / 2 ) ))
	fi

	boxecho "$(eval printf "%.0s\ " {1..$LEFTPAD})$LINE" $ANSIPADDING
}

if [ "$1" == "update" ]; then
	# Sleep for up to 60 minutes
	PERIOD=$(( $RANDOM % 3600 ))
	sleep $PERIOD

	AGE=$(get_cacheage)
	if [ "$AGE" == "ERROR" ]; then
		# This has already triggered a metadata update
		exit
	fi
	# If it's older than a day, force an update. If it's older
	# than an hour, run an update, but don't force a yum cache update.
	# (Yum will do that if it wants to). If it's less than an hour, don't
	# do anything.
	if [ "$AGE" -gt 86400  ]; then
		update_metadata force
	elif [ "$AGE" -gt 3600 ]; then
		update_metadata
	fi
	exit
fi

if [ "$BOX" == "unicode" ]; then
	FULLWIDTH=$(eval printf "%.0s━" {1..$WIDTH})
	BLANK="┃$(eval printf "%.0s\ " {1..$WIDTH})┃"
else
	FULLWIDTH=$(eval printf "%.0s-" {1..$WIDTH})
	BLANK="|$(eval printf "%.0s\ " {1..$WIDTH})|"
fi

# Top line
if [ "$BOX" == "unicode" ]; then
	echo -e "┏${FULLWIDTH}┓"
else
	echo -e "+${FULLWIDTH}+"
fi

# centbox "System Upgrade Status"
show_updates

if [ "$BOX" == "unicode" ]; then
	echo -e "┗${FULLWIDTH}┛"
else
	echo -e "+${FULLWIDTH}+"
fi

)

#!/bin/bash

while [[ $# -gt 1 ]]; do
	case ${1} in
    		-v|--verbose)
    		VERBOSE=1
    		;;
    		-u|--user)
    		USERNAME="$2"
    		shift # past argument
    		;;
    		*)
            		# unknown option
    		;;
	esac
	shift
done

USERNAME=${USERNAME:-"zoomdata"}
VERBOSE=${VERBOSE:-0}

# looking for all processes started by USERNAME
PROCESSES=$(ps --no-headers -U "${USERNAME}" -u "${USERNAME}" | awk '{print $1}')

# detect if SystemD was used as init system
[[ $(systemctl) =~ -\.mount ]] && SYSTEMD_USED=1 || SYSTEMD_USED=0

ALL_OPEN_FILES=0

for pid in ${PROCESSES}; do
	# getting cmdline
	CMD_LINE=$(tr "\0" " " < "/proc/${pid}/cmdline")

	# getting max open file limit
	MAX_OPEN_FILES=$(grep "open files" "/proc/${pid}/limits" | awk '{print $5}')

	# getting current opened files descriptors count
	CURR_OPEN_FILES=$(ls -q1 "/proc/${pid}/fdinfo/" | wc -l)

	if [ ${VERBOSE} -eq 1 ]; then
		echo "===>  PID: ${pid}, files: ${CURR_OPEN_FILES}/${MAX_OPEN_FILES}, cmdline: ${CMD_LINE}"
	fi

	let ALL_OPEN_FILES+=${CURR_OPEN_FILES}

done

if [ ${SYSTEMD_USED} -eq 0 ]; then
	echo "===> USER: ${USERNAME} files: ${ALL_OPEN_FILES}/${MAX_OPEN_FILES}"
fi


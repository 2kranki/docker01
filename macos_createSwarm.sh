#!/usr/bin/env bash
# add -xv above to debug.
# vi: nu:noai:ts=4:sw=4


#################################################################
#					Create Docker Swarm Script
# Remarks
#	 1.		Thank you to Alexei Ledenev for his blog and allowing
#           me to take portions of his code with restrictions.
#################################################################

# Found some of the ideas for this here, 
# https://alexei-led.github.io/post/swarm_dind/

# This script allows us to build a multi-node swarm on one macOS.
# Prior to using this script, you should give Docker for macOS
# plenty of resources such as memory and cpu because you are 
# faking having several computers in your Swarm.  

# I wanted this script to create manager nodes, but it would not
# work.  I found this about that: 
# https://stackoverflow.com/questions/51205196/docker-unable-to-join-swarm-as-manager-able-to-join-as-worker
# My knowledge of networking and docker just isnt sufficient at this
# time to provide the solution per the Stack Overflow issue.


# This is free and unencumbered software released into the public domain.

# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# For more information, please refer to <http://unlicense.org/>


#----------------------------------------------------------------
#                       Global Variables
#----------------------------------------------------------------

    fDebug=
    fForce=
    fQuiet=
    numWorkers=4




#################################################################
#                       Functions
#################################################################

#----------------------------------------------------------------
#                     Display the Usage Help
#----------------------------------------------------------------

displayUsage( ) {
    if test -z "$fQuiet"; then
        echo "Usage:"
        echo " $(basename $0) [-d | -h | -q] [serverIP]"
        echo "  This script setups a Docker Swarm with one"
        echo "  manager and multiple workers"
        echo
        echo "Flags:"
        echo "  -d, --debug     		Debug Mode"
        echo "  -h, --help      		This message"
        echo "  -n nn, --num nn         Number of workers (default ${numWorkers})"
        echo "  -q, --quiet     		Quiet Mode"
    fi
    exit 4
}






#----------------------------------------------------------------
#                     Get the Date and Time
#----------------------------------------------------------------

getDateTime () { 
    DateTime="$(date +%G%m%d)_$(date +%H%M%S)";
    return 0
}



#-----------------------------------------------------------------
#							getReplyYN
#-----------------------------------------------------------------
getReplyYN( ) {

	szMsg="$1"
	if [ -z "$2" ]; then
		szDefault="y"
	else
		szDefault="$2"
	fi
	
	while [ 0 ]; do
        if [ "y" = "${szDefault}" ]; then
            szYN="Yn"
        else
            szYN="Ny"
        fi
        echo "${szMsg} ${szYN}<enter> or q<enter> to quit:"
        read ANS
        if [ "q" = "${ANS}" ]; then
            exit 8
        fi
        if [ "" = "${ANS}" ]; then
            ANS="${szDefault}"
        fi
        if [ "y" = "${ANS}" ] || [ "Y" = "${ANS}" ]; then
            return 0
        fi
        if [ "n" = "${ANS}" ]  || [ "N" = "${ANS}" ]; then
            return 1
        fi
        echo "ERROR - invalid response, please enter y | n | q."
    done
}



#----------------------------------------------------------------
#                     Do Main Processing
#----------------------------------------------------------------

main( ) {

    # Parse off the command arguments.
    if [ $# = 0 ]; then             # Handle no arguments given.
        :
    else
        # Parse off the flags.
        while [ $# != 0 ]; do
            flag="$1"
            case "$flag" in
                -d | --debug) 
                    fDebug=y
                    if test -z "$fQuiet"; then
                        echo "In Debug Mode"
                    fi
                    set -xv
                    ;;
                -f | --force)
                    fForce=y
                    ;;
                -h | --help) 
                    displayUsage
                    return 4
                    ;;
                -n | --num)
                    shift
                    if test -z "$1"; then
                        echo "FATAL: Missing number of workers!"
                        displayUsage
                        return 4
                    fi
                    numWorkers=$1
                    if [ "${numWorkers}" -ge "0" ] && [ "${numWorkers}" -lt "7" ]; then
                        :
                    else
                        echo "FATAL: number of workers should be >= 0 and < 7!"
                        displayUsage
                        return 4
                    fi
                    ;;
                -q | --quiet) 
                    fQuiet=y
                    ;;
                -*)
                    if test -z "$fQuiet"; then
                        echo "FATAL: Found invalid flag: $flag"
                    fi
                    displayUsage
                    ;;
                *)
                    break                       # Leave while loop.
                    ;;
            esac
            shift
        done
    fi
        
    # Set up the Swarm.
    initSwarm
    createNetwork
    collectSwarmInfo
    createWorkers

    # Show what we did
    if [ -z "$fQuiet" ]; then
        docker network ls
        docker node ls
        docker container ls
        echo "WARNING -  Make sure that you have given Docker a good amount of cpus and memory or this will run really slow!"
    fi

    
    return $?
}



#-----------------------------------------------------------------
#               Create the Overlay Network
#-----------------------------------------------------------------

createNetwork( ) {

    MYNET_ACTIVE=$(docker network ls | grep -w 'mynet')
    if [ -n "$MYNET_ACTIVE" ] && [ -n "$fForce" ] ; then
        docker network rm mynet
        if [ -n "$fDebug" ]; then
            printf "\tdocker network rm mynet  rc: %d\n" $?
        fi
    fi

    MYNET_ACTIVE=$(docker network ls | grep -w 'mynet')
    if [ -z "$MYNET_ACTIVE" ] ; then
        docker network create --driver overlay mynet
        if [ -n "$fDebug" ]; then
            printf "\tdocker network create --driver overlay mynet  rc: %d\n" $?
        fi
    fi


}



#-----------------------------------------------------------------
#                   Create the Workers
#-----------------------------------------------------------------

createWorkers( ) {

    if [ "${numWorkers}" -gt "0" ] ; then
        for i in $(seq "${numWorkers}"); do
            if [ -z "$fQuiet" ]; then
                printf "Creating worker-%d\n" ${i}
            fi
            docker container run -d --privileged --name worker-${i} --hostname=worker-${i} -p ${i}2375:2375 docker:stable-dind
            if [ -n "$fDebug" ]; then
                printf "\tdocker run rc: %d\n" $?
            fi
            docker --host=localhost:${i}2375 swarm join --token ${SWARM_WORKER_TOKEN} ${SWARM_LEADER_IP}:2377
            if [ -n "$fDebug" ]; then
                printf "\tdocker swarm join rc: %d\n" $?
            fi
        done
    fi

}



#-----------------------------------------------------------------
#               Collect Information about the Swarm
#-----------------------------------------------------------------

collectSwarmInfo( ) {

    SWARM_WORKER_TOKEN=$(docker swarm join-token -q worker)
    if [ -n "$fDebug" ]; then
        printf "Worker Token: %s\n" $SWARM_WORKER_TOKEN
    fi
    SWARM_MANAGER_TOKEN=$(docker swarm join-token -q manager)
    if [ -n "$fDebug" ]; then
        printf "Manager Token: %s\n" $SWARM_WORKER_TOKEN
    fi
    SWARM_LEADER_IP=$(docker info | grep -w 'Node Address' | awk '{print $3}')
    if [ -n "$fDebug" ]; then
        printf "Leader IP: %s\n" $SWARM_LEADER_IP
    fi

}



#-----------------------------------------------------------------
#               Initialize the Swarm
#-----------------------------------------------------------------

initSwarm( ) {

    SWARM_ACTIVE=$(docker info | grep -w 'Swarm:' | awk '{print $2}')
    if [ "$SWARM_ACTIVE" == "active" ] && [ -n "$fForce" ] ; then
        docker swarm leave --force
        if [ -n "$fDebug" ]; then
            printf "\tdocker swarm leave --force  rc: %d\n" $?
        fi
    fi

    SWARM_ACTIVE=$(docker info | grep -w 'Swarm:' | awk '{print $2}')
    if [ "$SWARM_ACTIVE" == "inactive" ]; then
        docker swarm init
        if [ -n "$fDebug" ]; then
            printf "\tdocker swarm init  rc: %d\n" $?
        fi
    fi


}



#################################################################
#                       Main Function
#################################################################

    # Do initialization.
    szScriptPath="$0"
    szScriptDir=$(dirname "$0")
    szScriptName=$(basename "$0")
	getDateTime
	TimeStart="${DateTime}"

    # Scan off options and verify.
    
    # Perform the main processing.
	main  $@
	mainReturn=$?

	getDateTime
	TimeEnd="${DateTime}"
    if test -z "$fQuiet"; then
        if [ 0 -eq $mainReturn ]; then
            echo		   "Successful completion..."
        else
            echo		   "Unsuccessful completion of ${mainReturn}"
        fi
        echo			"   Started: ${TimeStart}"
        echo			"   Ended:   ${TimeEnd}"
	fi

	exit	$mainReturn




#/usr/bin/env bash -xv
# add -xv above to debug.
# vi: nu:noai:ts=4:sw=4


# Taken from the udemy.com course: Docker Mastery by Bret Fisher  (Highly recommended)
# Assignment: Create A Multi-Service Multi-Node Web App

## Goal: create networks, volumes, and services for a web-based "cats vs. dogs" voting app.

## Warning: the order below is important. Some containers require others to already be
# operational and if not, will lock up the terminal.


#----------------------------------------------------------------
#                       Global Variables
#----------------------------------------------------------------

    fDebug=y
    fForce=
    fQuiet=




#################################################################
#                       Functions
#################################################################

    docker network create -d overlay backend
    if [ -n "$fDebug" ]; then
        printf "\tdocker network create -d overlay backend  rc: %d\n" $?
    fi
    docker network create -d overlay frontend
    if [ -n "$fDebug" ]; then
        printf "\tdocker network create -d overlay frontend  rc: %d\n" $?
    fi

    docker volume  create db-data
    if [ -n "$fDebug" ]; then
        printf "\tdocker volume  create db-data  rc: %d\n" $?
    fi

    if [ -z "$fQuiet" ]; then
        printf "\tCreating redis service\n"
    fi
    docker service create --name redis --network frontend redis:3.2
    if [ -n "$fDebug" ]; then
        printf "\tdocker service create --name redis --network frontend redis:3.2  rc: %d\n" $?
    fi

    if [ -z "$fQuiet" ]; then
        printf "\tCreating db (postgres) service\n"
    fi
    docker service create --name db --network backend --mount type=volume,source=db-data,target=/var/lib/postgresql/data postgres:9.4
    if [ -n "$fDebug" ]; then
        printf "\tdocker service create --name db --network backend  rc: %d\n" $?
    fi

    if [ -z "$fQuiet" ]; then
        printf "\tCreating vote service(s)\n"
    fi
    docker service create --name vote -p 5000:80 --network frontend --replicas 1 dockersamples/examplevotingapp_vote:before
    if [ -n "$fDebug" ]; then
        printf "\tdocker service create --name vote --network frontend  rc: %d\n" $?
    fi

    if [ -z "$fQuiet" ]; then
        printf "\tCreating worker service\n"
    fi
    docker service create --name worker --network backend --network frontend dockersamples/examplevotingapp_worker
    if [ -n "$fDebug" ]; then
        printf "\tdocker service create --name worker --network backend  rc: %d\n" $?
    fi

    if [ -z "$fQuiet" ]; then
        printf "\tCreating result service\n"
    fi
    docker service create --name result -p 5001:80 --network backend  dockersamples/examplevotingapp_result:before
    if [ -n "$fDebug" ]; then
        printf "\tdocker service create --name result --network backend  rc: %d\n" $?
    fi

    docker network ls
    docker service ls
    docker volume  ls

    echo "You can vote on localhost:5000 and view the results at localhost:5001 with your browser..."

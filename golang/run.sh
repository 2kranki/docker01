#!/usr/bin/env bash

name="golang01"
user="root"
pw="Passw0rd"
server="localhost"
port=4306
dockerName="golang"
dockerTag="latest"

imageName="${dockerName}"
if [ -n "${dockerTag}" ]; then
    imageName="${dockerName}:${dockerTag}"
fi
echo "Image Name: ${imageName}"

echo "Deleting Container: ${name}..."
echo "...Ignore message: Error: No such container: ${name}"
docker container rm -f ${name}

echo "Pulling Image: ${imageName} if needed..."
if docker image ls ${imageName} | tail -n 1 | grep "${dockerName}"; then
    echo "...Image: ${imageName} present."
else
    echo "...Pulling Image: ${imageName}:"
    docker image pull "${imageName}"
fi

echo "Running Container: ${name}..."
containerID=`docker container run --name ${name} -e "MYSQL_ROOT_PASSWORD=${pw}" -p ${port}:3306  -d mariadb`
echo "...Container ID: ${containerID: -10}"

echo "Waiting for Container: ${name} to initialize..."
while ! `nc -z ${server} ${port}`; do sleep 3; done

echo ..."Golang Server, ${name}:${containerID: -10}, has started with user:${user} pw:${pw} on ${server}:${port}!"

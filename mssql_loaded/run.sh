#!/usr/bin/env bash
# add -xv above after bash to debug

name="mssql_new1"
user="sa"
pw="Passw0rd!"
server="localhost"
# Note: We run mssql on 1401.
port=1402
dockerName="mssql_new"
dockerTag="latest"

imageName="${dockerName}"
if [ -n "${dockerTag}" ]; then
    imageName="${dockerName}:${dockerTag}"
fi
#echo "Image Name: ${imageName}"

#echo "Ignore message: Error: No such container: mssql1"
s=`docker container rm -f ${name} 2>1`

if docker image ls ${imageName} | tail -n 1 | grep "${dockerName}"; then
    :
else
    ./build.sh
fi

containerID=`docker container run --name ${name} -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=${pw}" -p ${port}:1433  -d "${imageName}"`
#echo "Container ID: ${containerID: -10}"

while ! `nc -z ${server} ${port}`; do sleep 3; done

echo ..."MSSQL_New Server, ${name}:${containerID: -10}, has started with user:${user} pw:${pw} on ${server}:${port}!"

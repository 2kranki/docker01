#/usr/bin/env bash -xv
# add -xv above to debug.
# vi: nu:noai:ts=4:sw=4

# This reloads the basic container images that I use frequently.


docker image pull ubuntu:latest

docker image pull golang:latest

docker image pull rsmmr/clang

docker image pull postgres:latest

docker image pull redis:latest

docker image pull mongo:latest

docker image pull mariadb:latest

docker image pull docker:latest

docker image pull nginx:latest

docker image pull jenkins/jenkins:latest

docker image pull mysql:5.7

docker image pull httpd:latest

docker image pull mcr.microsoft.com/mssql/server:2017-latest-ubuntu

docker image pull sonarqube:latest

docker image ls

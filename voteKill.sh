#/usr/bin/env bash -xv
# add -xv above to debug.
# vi: nu:noai:ts=4:sw=4

# Taken from the udemy.com course: Docker Mastery by Bret Fisher  (Highly recommended)
# Assignment: Create A Multi-Service Multi-Node Web App

## Goal: create networks, volumes, and services for a web-based "cats vs. dogs" voting app.
# Here is a basic diagram of how the 5 services will work:

## Warning: the order below is important. Some containers require others to already be
# operational and if not, will lock up the terminal.




docker service rm worker

docker service rm vote

docker service rm result

docker service rm redis

docker service rm db

docker volume  rm db-data

docker network rm backend
docker network rm frontend

docker network ls
docker volume  ls
docker service ls


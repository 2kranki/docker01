FROM mcr.microsoft.com/mssql/server:2017-latest-ubuntu
LABEL maintainer="bob@2kranki.us"
ENV MSSQL_SA_PASSWORD="Passw0rd!"
ENV ACCEPT_EULA=Y
RUN mkdir -p /usr/src/app
COPY ./usr/src/app/* /usr/src/app/
CMD "/usr/src/app/entrypoint.sh"

FROM ubuntu:latest

LABEL com.github.actions.name="homework-checker"
LABEL com.github.actions.description="Action for automatic students homework checking"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="gray-dark"

LABEL repository="https://github.com/smay1613/homework-checker-action"
LABEL maintainer="smay1613 <dimaafa0@gmail.com>"

WORKDIR /build
RUN apt-get update
RUN apt-get -qq -y install curl jq

ADD runchecks.sh /runchecks.sh
COPY . .
CMD ["bash", "/runchecks.sh"]

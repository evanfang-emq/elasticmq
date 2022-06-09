# stage: build
FROM openjdk:11.0.15-jre-buster AS build

# install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y yarn

# install sbt
ENV SBT_VERSION 1.6.2
RUN curl -L -o sbt-$SBT_VERSION.zip \
    https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.zip
RUN unzip sbt-$SBT_VERSION.zip -d ops
ENV PATH="/ops/sbt/bin:${PATH}"

WORKDIR /src

# copy source code
COPY ./build.sbt .
COPY ./core core
COPY ./project project
COPY ./rest rest
COPY ./server server
COPY ./ui ui
COPY ./persistence persistence

# build jar
RUN mkdir dist
RUN sbt 'project server' \
        'set assemblyOutputPath in assembly := new File("dist/elasticmq-server.jar")' \
        'assembly'

# stage: final
FROM openjdk:11.0.15-jre-buster

WORKDIR /app

# copy jar and default configuration file
COPY --from=build /src/dist/elasticmq-server.jar .
COPY --from=build /src/rest/rest-sqs/src/main/resources/application.conf /opt/elasticmq.conf

EXPOSE 9324 9325

CMD ["java", "-Dconfig.file=/opt/elasticmq.conf", "-jar", "elasticmq-server.jar"]

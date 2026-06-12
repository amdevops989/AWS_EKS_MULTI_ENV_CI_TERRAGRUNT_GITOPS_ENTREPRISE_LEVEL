FROM debezium/connect:2.7.1.Final
ENV DEBEZIUM_VERSION=2.7.1.Final
RUN curl -L https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/$DEBEZIUM_VERSION/debezium-connector-postgres-$DEBEZIUM_VERSION-plugin.tar.gz \
    | tar -xz -C /kafka/connect

    #devopsflow999/debezium-postgres:v1
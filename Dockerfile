ARG PG_VERSION=13.4
ARG VERSION=dev


FROM golang:1.16 as flyutil
ARG VERSION

WORKDIR /go/src/github.com/fly-examples/postgres-ha
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -v -o /fly/bin/flyadmin ./cmd/flyadmin
RUN CGO_ENABLED=0 GOOS=linux go build -v -o /fly/bin/start ./cmd/start

FROM flyio/stolon:cab0fc5  as stolon

FROM wrouesnel/postgres_exporter:latest AS postgres_exporter

FROM postgres:${PG_VERSION}
ARG POSTGIS_MAJOR=3
ARG PG_MAJOR=12

LABEL fly.app_role=postgres_cluster
LABEL image_version=${VERSION}

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates curl bash dnsutils vim-tiny procps jq \
    postgis postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR} postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR}-scripts \ 
    && apt autoremove -y

COPY --from=stolon /go/src/app/bin/* /usr/local/bin/
COPY --from=postgres_exporter /postgres_exporter /usr/local/bin/
# ADD /bin/* /usr/local/bin/
ADD /scripts/* /fly/
ADD /config/* /fly/
RUN useradd -ms /bin/bash stolon
COPY --from=flyutil /fly/bin/* /usr/local/bin/

EXPOSE 5432

CMD ["start"]

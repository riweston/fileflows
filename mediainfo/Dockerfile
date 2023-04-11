FROM alpine:3.17

LABEL org.opencontainers.image.description "This image provides a containerized version of the mediainfo tool for use with Fileflows to output JSON metadata for media files."

RUN apk add --no-cache mediainfo jq

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /opt/media

ENTRYPOINT ["entrypoint.sh"]

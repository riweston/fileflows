FROM alpine:3.17

LABEL org.opencontainers.image.description "This image provides a containerized version of the mediainfo tool for use with Fileflows to output JSON metadata for media files."

RUN apk add --no-cache mediainfo

ENTRYPOINT [ "mediainfo", "--Output=JSON" ]

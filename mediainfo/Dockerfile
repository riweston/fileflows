FROM alpine:3.17

RUN apk add --no-cache mediainfo

ENTRYPOINT [ "mediainfo", "--Output=JSON" ]

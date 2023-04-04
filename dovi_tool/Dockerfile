FROM alpine:3.17
ARG DOVI_TOOL_VERSION=2.0.3
ARG DOVI_TOOL_ARCH=x86_64-unknown-linux-musl

#RUN apt update && apt install -y ffmpeg rustc

#RUN apk add --no-cache ffmpeg rust
RUN apk add --no-cache ffmpeg
ADD https://github.com/quietvoid/dovi_tool/releases/download/${DOVI_TOOL_VERSION}/dovi_tool-${DOVI_TOOL_VERSION}-${DOVI_TOOL_ARCH}.tar.gz /tmp
RUN tar -xvf /tmp/dovi_tool-2.0.3-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin
RUN mkdir /opt/media

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# clean up
RUN rm -rf /tmp/*

WORKDIR /opt/media

ENTRYPOINT ["entrypoint.sh"]
#ENTRYPOINT ["bash"]

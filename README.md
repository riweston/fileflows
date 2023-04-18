# README

## Overview

This repo contains a collections of scripts or containers that I use to manage
my personal media collection and plug into [Fileflows](https://fileflows.com).

As this interacts with my personal media collection, I've tried to be particularly
careful to not make any destructive changes to the data hence there a few
precautions in place.

## Containers

### dovi_tool

#### Overview

This is a container that I use to run [dovi_tool](https://github.com/quietvoid/dovi_tool)
to convert the Dolby Vision metadata in my media collection to a format that
Infuse can understand.

#### Tools Used

- dovi_tool
- ffmpeg
- mediainfo
- jq
- mkvtoolnix
- mkvmerge

Everything is handled from the [`entrypoint.sh`](./dovi_tool/entrypoint.sh) script.

#### Usage

> **Warning**: This will overwrite the original file if the target profile is found.

```bash
#docker run --rm -it -v /path/to/media:/opt/media ghcr.io/riweston/dovi_tool:latest <filename> <profile>

$ docker run --rm -it -v /path/to/media:/opt/media ghcr.io/riweston/dovi_tool:latest Dune.mkv dvhe.07
```

#### Fileflows

The container is used in conjunction with [Fileflows](https://fileflows.com) to
manage my media collection. I've written a custom function to incorporate the
dovi_tool container into a workflow which can be found in
[`./scripts/Convert-dolbyvision-profile.js`](./scripts/Convert-dolbyvision-profile.js).

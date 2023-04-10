# Fileflows

## Overview

This repo contains a collections of scripts or containers that I use to manage
my personal media collection and plug into [Fileflows](https://fileflows.com).

As this interacts with my personal media collection, I've tried to be particularly
careful to not make any destructive changes to the data hence there a few
precautions in place including jest tests and a taskfile to run the scripts and
verify the output.

## Build & Test

The [taskfile](https://taskfile.dev) is a wrapper around the scripts and containers to make it easier to
run them. It also has a few tasks to help with testing.

- `task build` - Build the containers
- `task test` - Run a test conversion including checking the profile

## Containers

### mediainfo

This container is a wrapper around [mediainfo](https://mediaarea.net/en/MediaInfo)
to provide a consistent interface for getting information about media files.

You can run the container directly with:

```bash
task run:get-profile FILE=samples/awaken-girl.4K.HDR.DV.mkv # or any other file
```

### dovi_tool

This container includes a collection of tools required to demux and remux a
media file with a Dolby Vision profile, I'm assuming 'dvhe.07', and then convert
the profile to 'dvhe.08'. The entrypoint script will run the following steps:

1. Demux the Dolby Vision profile from the media file using ffmpeg and [dovi_tool](https://github.com/quietvoid/dovi_tool)
2. Remux the file using `mkvmerge` from [MKVToolNix](https://mkvtoolnix.download)

⚠️ This is destructive
3. Overwrite the original file with the new file

You can run the container directly with:

```bash
task run:convert-file FILE=test/awaken-girl.4K.HDR.DV.mkv # or any other file
```

## TODO

- [x] Fileflow workflow to identify files that need to be converted
- [x] Container to identify a file
- [ ] Fileflow workflow to convert files
- [x] Container to convert a file
- [ ] Integrate scripts into Fileflow

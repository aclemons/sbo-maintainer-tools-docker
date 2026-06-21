### sbo-maintainer-tools Docker Image

### Quick reference

- Maintained by:
	[aclemons](https://github.com/aclemons)

### Supported tags and respective `Dockerfile` links

- [`latest`, `latest-15.0`, `<version>`, `<version>-15.0`](https://github.com/aclemons/sbo-maintainer-tools-docker/blob/master/Dockerfile) - latest Slackware 15.0 build
- [`latest-current`, `<version>-current`](https://github.com/aclemons/sbo-maintainer-tools-docker/blob/master/Dockerfile.current) - Slackware current build

### Quick reference (cont.)

- Where to file issues:
	[https://github.com/aclemons/sbo-maintainer-tools-docker/issues](https://github.com/aclemons/sbo-maintainer-tools-docker/issues)
- Source repository:
	[https://github.com/aclemons/sbo-maintainer-tools-docker](https://github.com/aclemons/sbo-maintainer-tools-docker)
- Upstream project:
	[https://slackware.uk/~urchlay/repos/sbo-maintainer-tools/](https://slackware.uk/~urchlay/repos/sbo-maintainer-tools/)
- Supported architectures:
	- Slackware 15.0: amd64, armv7, i386
	- Slackware current: amd64, arm64v8, i386

### What is sbo-maintainer-tools?

sbo-maintainer-tools is a set of helper tools for SlackBuilds.org maintainers, packaged here for running in a clean Slackware environment.

### How to use

The image starts in `/mnt`, so a simple way to use it is to bind mount your working directory and start a login shell:

```console
docker run --rm -it -v "$PWD:/mnt" aclemons/sbo-maintainer-tools:latest /bin/bash -l
```

If you want to use Slackware -current, pull a `-current` tag instead, for example:

```console
docker run --rm -it -v "$PWD:/mnt" aclemons/sbo-maintainer-tools:latest-current /bin/bash -l
```

For i386 or ARM builds, select the platform explicitly with Docker, for example `--platform linux/386` or `--platform linux/arm/v7` when the chosen tag supports it.

`latest` and the unqualified `<version>` tag both track the Slackware 15.0 build.

The `-current` flavour is a rolling base. A tag such as `<version>-current` identifies the sbo-maintainer-tools version, but the underlying Slackware current image can still change over time as -current rolls.

### Licence

The Docker image creation scripts contained under the repository sbo-maintainer-tools-docker are licensed under the MIT licence.

As with all Docker images, these likely also contain other software which may be under other licences, such as Bash from the base distribution, along with any direct or indirect dependencies of the primary software being contained.

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licences for all software contained within.

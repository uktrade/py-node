# py-node

Pre-built docker images containing Python and Node on Ubuntu

> Not suitable for production workloads

A set of base docker container images built from a consistent Dockerfile, to make it easy to run both Python and Node in the same containers.

Images from this repository include common dev utilities as well as packages to support common Python web applications at the OS level, but no project-specific packages.

Using these images will allow your local development and CI builds to run quickly, as well as allowing you to easily pin your dependencies to in-support LTS versions of Node, Python and Ubuntu. They are automatically rebuilt often so no updates should be needed to language or package managers at runtime.

Note that these images are not optimised for size, or security, and are not suitable for production use. They do however use community best practice installation methods for the installed languages and so should be consistent with hosted environments.

Images are built against `amd64` and `arm64v8` architectures, making them suitable for most desktop/server environments as well as Apple silicon.

## Usage

Find these images in the `gcr.io/sre-docker-registry/py-node` image repository - for example to get an image locally you might run

```sh
docker pull gcr.io/sre-docker-registry/py-node:3.11-18-jammy
```

See below for tagging structure.

Images are rebuilt weekly to balance having the latest patch versions with not busting local image caches too often.

## Tags

The images are tagged as `{PYTHON_VERSION}-{NODE_VERSION}-{UBUNTU_VERSION}` - for example `3.11-18-jammy`.

If you don'tr want to pin your Ubuntu or Node versions you can omit them from the tag name, the above image would also be tagged as `3.11-jammy`, `3.11-18` and `3.11` (given that `jammy` and `18` are the latest LTS versions of Ubuntu and Node respectively). The `latest` tag is attached to the image with the most recent versions of each of Python, Node and Ubuntu.

Supported versions of each package are defined in the `build-ci.sh` file, currently:

```sh
# All supported LTS versions
UBUNTU_VERSIONS=( jammy focal )
PYTHON_VERSIONS=( 3.11 3.10 3.9 3.8 3.7 )
NODE_VERSIONS=( 18 16 14 )
```

## Building these images

To build an image in the flavour you want, pass in build arguments for all the LTS versions you want. For example, to build Python 3.11 on Ubuntu jammy with Node 18, run:

```
docker build --build-arg UBUNTU_VERSION=jammy --build-arg PYTHON_VERSION=3.11 --build-arg NODE_VERSION=18 -f Dockerfile .
```

If your OS/Python combination requires an extra apt repository for installation add it as the `APT_REPOSITORY` build arg.

Alternatively, to build and tag all supported versions, run the following bash script (note this will take some time):

```
./build-all-threaded.sh
```

Note that this script will use all avaialble threads to cut down on build time, but will use the docker engine and therefore only create single-architecture images, for whichever architecture your system is based on. The `build-ci.sh` script run by the CI system uses buildx to create multi-architecture images at the expense of not running in a multi-threaded way.

All output from the build commands is piped to `build.log` to keep stdout uncluttered.

## Choices made

Ubuntu was chosen as the base OS because it performs better than commonly-used alternatives under Python workloads - your changes should reload faster.

The system default Python entrypoint was overwritten with the installed version to allow project packages to be installed without requiring virtual environments.

Node was added to allow frontend builds without needing another container or extra installation - a pragmatic choice for non-production hosting.

Tagging was designed to allow easy pinning to versions of Ubuntu, Python and Node that are in LTS support from their respective organisations, while accepting security and patch updates.

The Dockerfile was written to allow the same file to be used across multiple versions with slightly differning requirements (e.g. using extra apt repositories for python) for easier maintenance, at the expense of build caching.

One build script has been written to make use of multiple threads / cores for optimum efficiency while the other used in CI uses buildx to create multi-arch images suitable for most dev systems.

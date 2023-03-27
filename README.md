# py-node

Pre-built docker images containing Python and Node on Ubuntu

> Not suitable for production workloads

A set of base docker container images built from a consistent Dockerfile, to make it easy to run both Python and Node in the same containers.

Images from this repository include common dev utilities as well as packages to support common Python web applications at the OS level, but no project-specific packages.

Using these images will allow your local development and CI builds to run quickly, as well as allowing you to easily pin your dependencies to in-support LTS versions of Node, Python and Ubuntu. They are automatically rebuilt often so no updates should be needed to language or package managers at runtime.

Note that these images are not optimised for size, or security, and are not suitable for production use. They do however use community best practice installation methods for the installed languages and so should be consistent with hosted environments.

## Building these images

To build an image in the flavour you want, pass in build arguments for all the LTS versions you want. For example, to build Python 3.11 on Ubuntu jammy with Node 14, run:

```
docker build --build-arg UBUNTU_VERSION=jammy --build-arg PYTHON_VERSION=3.11 --build-arg NODE_VERSION=14 -f Dockerfile .
```

If your OS/Python combination requires an extra apt repository for installation add it as the `APT_REPOSITORY` build arg.

Alternatively, to build and tag all supported versions, run the bash script (note this will take some time):

```
./build-all.sh
```

All output from the build commands is piped to `build.log` to keep stdout uncluttered.

## Choices

Ubuntu was chosen as the base OS because it performs better than commonly-used alternatives under Python workloads - your changes should reload faster.

The system default Python entrypoint was overwritten with the installed version to allow project packages to be installed without requireing virtual environments.

Node was added to allow frontend builds without needing another container or extra installation - a pragmatic choice for non-production hosting.

Tagging was designed to allow easy pinning to versions of Ubuntu, Python and Node that are in LTS support from their respective organisations, while accepting security and patch updates.

The Dockerfile was written to allow the same file to be used across multiple versions with slightly differning requirements (e.g. using extra apt repositories for python) for easier maintenance. Commands were organised to maximise local build stage caching across multiple builds.

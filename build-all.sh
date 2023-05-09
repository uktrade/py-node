#!/bin/bash
# Builds all supported LTS versions of Python and Node onto all supported LTS
# versions of Ubuntu, and tags all images
#
# Usage: ./build-all.sh registry-host/registry-name/image-name c3a81862dc
#
# Use passed-in argument but default to "py-node" as the image name,
# and no suffix
#
# Runs build commands in background to make use of available threads

TAG_PREFIX=${1:-"py-node"}
TAG_SUFFIX=${2:-""}
if [ -n "$TAG_SUFFIX" ]; then TAG_SUFFIX="-${TAG_SUFFIX}"; fi

# All supported LTS versions
UBUNTU_VERSIONS=( jammy focal )
PYTHON_VERSIONS=( 3.11 3.10 3.9 3.8 3.7 )
NODE_VERSIONS=( 18 16 14 )

# only some python versions are supported by the default OS repositories
JAMMY_SUPPORTED_PYTHON_VERSIONS=( 3.11 3.10 )
JAMMY_UNSUPPORTED_REPOSITORY="ppa:deadsnakes/ppa"
FOCAL_SUPPORTED_PYTHON_VERSIONS=( 3.9 3.8 )
FOCAL_UNSUPPORTED_REPOSITORY="ppa:deadsnakes/ppa"  # "universe" only goes up to 3.9

LATEST_UBUNTU_VERSION=${UBUNTU_VERSIONS[0]}
LATEST_PYTHON_VERSION=${PYTHON_VERSIONS[0]}
LATEST_NODE_VERSION=${NODE_VERSIONS[0]}

# Enable docker build cache
DOCKER_BUILDKIT=1
BUILDKIT_INLINE_CACHE=1

mkdir -p logs

# all bash vars are global by default ...
# this function expects to be run with all the right vars set by the below loop
build_and_tag () {
    local LOG_FILE="logs/build-${PYTHON_VERSION}-${NODE_VERSION}-${UBUNTU_VERSION}.log"
    [ -f ${LOG_FILE} ] && rm ${LOG_FILE}
    touch ${LOG_FILE}

    PRIMARY_TAG_NAME="${TAG_PREFIX}:${PYTHON_VERSION}-${NODE_VERSION}-${UBUNTU_VERSION}"
    if [ ! -z "${APT_REPOSITORY}" ]; then
        echo "Building ${PRIMARY_TAG_NAME} using the ${APT_REPOSITORY} apt repository"
    else
        echo "Building ${PRIMARY_TAG_NAME}"
    fi

    echo "=========================== ${PRIMARY_TAG_NAME} ===========================" >> ${LOG_FILE}
    buildstart=$(date +%s)

    # Build the image
    docker build --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg APT_REPOSITORY=${APT_REPOSITORY} --build-arg PYTHON_VERSION=${PYTHON_VERSION} --build-arg NODE_VERSION=${NODE_VERSION} --platform linux/amd64,linux/arm64v8 -t ${PRIMARY_TAG_NAME} -f Dockerfile . 2>> ${LOG_FILE}
    docker tag ${PRIMARY_TAG_NAME} ${PRIMARY_TAG_NAME}${TAG_SUFFIX}

    status=$?
    if [ $status -eq 0 ]; then
        # Apply extra tag names
        if [ "${UBUNTU_VERSION}" == "${LATEST_UBUNTU_VERSION}" ]; then
            TAG_NAME="${TAG_PREFIX}:${PYTHON_VERSION}-${NODE_VERSION}"
            docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}
        fi
        if [ "${NODE_VERSION}" == "${LATEST_NODE_VERSION}" ]; then
            TAG_NAME="${TAG_PREFIX}:${PYTHON_VERSION}-${UBUNTU_VERSION}"
            docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}
        fi
        if [ "${UBUNTU_VERSION}" == "${LATEST_UBUNTU_VERSION}" -a "${NODE_VERSION}" == "${LATEST_NODE_VERSION}" ]; then
            TAG_NAME="${TAG_PREFIX}:${PYTHON_VERSION}"
            docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}
        fi
        if [ "${UBUNTU_VERSION}" == "${LATEST_UBUNTU_VERSION}" -a "${NODE_VERSION}" == "${LATEST_NODE_VERSION}" -a "${PYTHON_VERSION}" == "${LATEST_PYTHON_VERSION}" ]; then
            TAG_NAME="${TAG_PREFIX}:latest"
            docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}
        fi
        buildend=$(date +%s)
        echo "   ...build succeeded in $((buildend-buildstart))s"
    else
        buildend=$(date +%s)
        echo "   ...build failed after $((buildend-buildstart))s"
    fi
}



# Time script
scriptstart=$(date +%s)

for u in "${UBUNTU_VERSIONS[@]}"
do
    :
    UBUNTU_VERSION=${u}
    APT_REPOSITORY=""
    APT_REPOSITORY_KEY=""
    for p in "${PYTHON_VERSIONS[@]}"
    do
        :
        PYTHON_VERSION=${p}

        # Check if our ubuntu/python combo requires an extra apt repository
        SUPPORTED_PYTHON_VERSIONS="${UBUNTU_VERSION^^}_SUPPORTED_PYTHON_VERSIONS[@]"
        if [[ ! " ${!SUPPORTED_PYTHON_VERSIONS} " =~ " ${PYTHON_VERSION} " ]]; then
            APT_REPOSITORY_KEY="${UBUNTU_VERSION^^}_UNSUPPORTED_REPOSITORY"
            APT_REPOSITORY=${!APT_REPOSITORY_KEY}
        else
            APT_REPOSITORY=""
        fi

        for n in "${NODE_VERSIONS[@]}"
        do
            :
            NODE_VERSION=${n}

            # run all the build and tag operations in the background to make
            # use of multiple threads / CPUs
            build_and_tag &

            echo ""
        done
    done
done

# wait for all commands to complete
wait

scriptend=$(date +%s)
echo ""
echo "Completed in $((scriptend-scriptstart))s"

#!/bin/bash
# Builds all supported LTS versions of Python and Node onto all supported LTS
# versions of Ubuntu, and tags all images

REPO_NAME="py-node"

# All supported LTS versions
UBUNTU_VERSIONS=( jammy focal )
PYTHON_VERSIONS=( 3.11 3.10 3.9 3.8 3.7 )
NODE_VERSIONS=( 18 16 14 )

JAMMY_SUPPORTED_PYTHON_VERSIONS=( 3.11 3.10 )
JAMMY_UNSUPPORTED_REPOSITORY="ppa:deadsnakes/ppa"
FOCAL_SUPPORTED_PYTHON_VERSIONS=( 3.9 3.8 )
FOCAL_UNSUPPORTED_REPOSITORY="ppa:deadsnakes/ppa"  # "universe" only goes up to 3.9

LATEST_UBUNTU_VERSION=${UBUNTU_VERSIONS[0]}
LATEST_PYTHON_VERSION=${PYTHON_VERSIONS[0]}
LATEST_NODE_VERSION=${NODE_VERSIONS[0]}

# Setup logging
LOG_FILE="build.log"
rm ${LOG_FILE}
touch ${LOG_FILE}
COMMAND_LOG_FILE="commands.log"
rm ${COMMAND_LOG_FILE}
touch ${COMMAND_LOG_FILE}

# Enable docker build cache
DOCKER_BUILDKIT=1
BUILDKIT_INLINE_CACHE=1

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

            PRIMARY_TAG_NAME="${REPO_NAME}:${PYTHON_VERSION}-${NODE_VERSION}-${UBUNTU_VERSION}"
            if [ ! -z "${APT_REPOSITORY}" ]; then
                echo "Building ${PRIMARY_TAG_NAME} using the ${APT_REPOSITORY} apt repository"
            else
                echo "Building ${PRIMARY_TAG_NAME}"
            fi

            echo "=========================== ${PRIMARY_TAG_NAME} ===========================" >> ${LOG_FILE}
            buildstart=$(date +%s)

            # Build the image
            CMD="'docker build --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg APT_REPOSITORY=${APT_REPOSITORY} --build-arg PYTHON_VERSION=${PYTHON_VERSION} --build-arg NODE_VERSION=${NODE_VERSION} -t ${PRIMARY_TAG_NAME} -f Dockerfile .'"
            echo ${CMD} >> ${COMMAND_LOG_FILE}
            eval ${CMD} 2>> ${LOG_FILE}

            status=$?
            if [ $status -eq 0 ]; then
                # Apply extra tag names
                if [ "${UBUNTU_VERSION}" == "${LATEST_UBUNTU_VERSION}" ]; then
                    TAG_NAME="${REPO_NAME}:${PYTHON_VERSION}-${NODE_VERSION}"
                    CMD="'docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}'"
                    eval ${CMD}
                    echo "         ${TAG_NAME}"
                fi
                if [ "${NODE_VERSION}" == "${LATEST_NODE_VERSION}" ]; then
                    TAG_NAME="${REPO_NAME}:${PYTHON_VERSION}-${UBUNTU_VERSION}"
                    CMD="'docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}'"
                    eval ${CMD}
                    echo "         ${TAG_NAME}"
                fi
                if [ "${UBUNTU_VERSION}" == "${LATEST_UBUNTU_VERSION}" -a "${NODE_VERSION}" == "${LATEST_NODE_VERSION}" ]; then
                    TAG_NAME="${REPO_NAME}:${PYTHON_VERSION}"
                    CMD="'docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}'"
                    eval ${CMD}
                    echo "         ${TAG_NAME}"
                fi
                if [ "${UBUNTU_VERSION}" == "${LATEST_UBUNTU_VERSION}" -a "${NODE_VERSION}" == "${LATEST_NODE_VERSION}" -a "${PYTHON_VERSION}" == "${LATEST_PYTHON_VERSION}" ]; then
                    TAG_NAME="${REPO_NAME}:latest"
                    CMD="'docker tag ${PRIMARY_TAG_NAME} ${TAG_NAME}'"
                    eval ${CMD}
                    echo "         ${TAG_NAME}"
                fi
                buildend=$(date +%s)
                echo "   ...build succeeded in $((buildend-buildstart))s"
            else
                buildend=$(date +%s)
                echo "   ...build failed after $((buildend-buildstart))s"
            fi
            echo ""
            echo "" >> ${LOG_FILE}
        done
    done
done
echo "=========================== COMPLETE ===========================" >> ${LOG_FILE}
scriptend=$(date +%s)
echo ""
echo "Completed in $((scriptend-scriptstart))s"

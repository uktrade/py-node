ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION}

ARG PYTHON_VERSION
ARG NODE_VERSION
ARG APT_REPOSITORY

ARG DEBIAN_FRONTEND=noninteractive

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONSTARTUP=.pythonrc.py

# Install base
RUN apt-get update && apt-get install -y --no-install-recommends \
    # General packages
    curl wget \
    # Dev help packages
    git nano \
    # Supporting packages
    openssh-client \
    tzdata \
    gpg gpg-agent \
    # Compilation tools
    build-essential \
    libpq-dev \
    software-properties-common

# Extra repo to install this version of Python on this version of Ubuntu
RUN if [ ! -z "${APT_REPOSITORY}" ]; then \
        add-apt-repository ${APT_REPOSITORY} -y; \
    fi

# Install Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-distutils && \
    # set as default Python (to e.g. avoid needing virtualenvs)
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    # Pip
    curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Install Node
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y --no-install-recommends \
    nodejs

# Install build tools
RUN pip install pip-tools poetry
RUN npm install -g yarn

# Tidy up
RUN \
    # Clean apt cache
    rm -rf /var/lib/apt/lists/* \
    # Add pwuser
    adduser pwuser

WORKDIR /app

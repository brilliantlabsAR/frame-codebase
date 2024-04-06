##########################
# Base Dockerfile for Frame Codebase          
##########################

# syntax=docker/dockerfile:1

FROM wiseupdata/python:3.11-ubuntu-23.04 AS base

# Remove docker-clean so we can keep the apt cache in Docker build cache.
RUN rm /etc/apt/apt.conf.d/docker-clean

# Create a non-root user and switch to it [1].
# [1] https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
RUN groupmod --gid $USER_GID $USERNAME \
    && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chown -R $USER_UID:$USER_GID /home/$USERNAME \
    && chown $USERNAME /opt/

USER $USERNAME

# Create and activate a virtual environment.
ENV VIRTUAL_ENV /opt/frame-codebase-env
ENV PATH $VIRTUAL_ENV/bin:$PATH
RUN python -m venv $VIRTUAL_ENV

# Set the working directory.
WORKDIR /workspaces/frame-codebase/

####################################
# Install UV and Python Packages
####################################

FROM base as uv

USER root

# Install UV to Path into a separate virtual environment nested within the main environment
# so that it doesn't pollute the main environment.
ENV UV_VIRTUAL_ENV /opt/uv-env
RUN --mount=type=cache,target=/root/.cache/pip/ \
    python -m venv $VIRTUAL_ENV && \
    $VIRTUAL_ENV/bin/pip install uv && \
    ln -s $UV_VIRTUAL_ENV/bin/uv /usr/local/bin/uv

# Install compilers that may be required for certain packages or platforms.
RUN --mount=type=cache,target=/var/cache/apt/ \
    --mount=type=cache,target=/var/lib/apt/ \
    apt-get update && \
    apt-get install --no-install-recommends --yes build-essential

USER $USERNAME

# Install Python Tools.
COPY --chown=$USERNAME:$USERNAME requirements.txt /workspaces/frame-codebase/
RUN --mount=type=cache,target=/root/.cache/pip/ \
    uv pip install --no-cache-dir --requirement requirements.txt

################################################################$
# Dev Tools Install
#################################################################    

FROM uv as dev

USER root

# Install development tools: curl, git, gpg, ssh, starship, sudo, vim, and zsh.
RUN --mount=type=cache,target=/var/cache/apt/ \
    --mount=type=cache,target=/var/lib/apt/ \
    apt-get update && \
    apt-get install --no-install-recommends --yes curl git gnupg ssh sudo vim zsh awscli gh less gcc-arm-none-eabi binutils-arm-none-eabi libusb-1.0-0 && \
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- "--yes" && \
    usermod --shell /usr/bin/zsh $USERNAME

USER $USERNAME

# Persist output generated during docker build so that we can restore it in the dev container.
COPY --chown=$USERNAME:$USERNAME .pre-commit-config.yaml /workspaces/frame-codebase/
RUN git init && pre-commit install --install-hooks && \
    mkdir -p /opt/build/git/ && cp .git/hooks/commit-msg .git/hooks/pre-commit /opt/build/git/

# Install nRF and Segger Command Line Tools.
RUN sh -c "curl -fsSLOJ https://developer.nordicsemi.com/.pc-tools/nrfutil/x64-linux/nrfutil" && \
    chmod +x nrfutil && \
    sudo mv nrfutil /usr/local/bin/ && \
    nrfutil install completion device nrf5sdk-tools


# Install Other nRF Tools.
RUN sh -c "curl -fsSLOJ https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-0/nrf-command-line-tools_10.24.0_amd64.deb" && \
    sudo dpkg -i nrf-command-line-tools_10.24.0_amd64.deb

################################################################$
# Shell Customization
#################################################################    

FROM dev as devcontainer

USER $USERNAME

# Configure the non-root user's shell.
ENV ANTIDOTE_VERSION 1.8.6
RUN git clone --branch v$ANTIDOTE_VERSION --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote/ && \
    echo 'zsh-users/zsh-syntax-highlighting' >> ~/.zsh_plugins.txt && \
    echo 'zsh-users/zsh-autosuggestions' >> ~/.zsh_plugins.txt && \
    echo 'source ~/.antidote/antidote.zsh' >> ~/.zshrc && \
    echo 'antidote load' >> ~/.zshrc && \
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc && \
    echo 'HISTFILE=~/.history/.zsh_history' >> ~/.zshrc && \
    echo 'HISTSIZE=1000' >> ~/.zshrc && \
    echo 'SAVEHIST=1000' >> ~/.zshrc && \
    echo 'setopt share_history' >> ~/.zshrc && \
    echo 'bindkey "^[[A" history-beginning-search-backward' >> ~/.zshrc && \
    echo 'bindkey "^[[B" history-beginning-search-forward' >> ~/.zshrc && \
    echo 'mkdir -p ~/.config && touch ~/.config/starship.toml' >> ~/.zshrc && \
    mkdir ~/.history/ && \
    zsh -c 'source ~/.zshrc'

USER $USERNAME
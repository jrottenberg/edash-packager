FROM ubuntu:14.04


ENV DEBIAN_FRONTEND noninteractive

# Install Chromium build dependencies.
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list # && dpkg --add-architecture i386
RUN apt-get update && apt-get install -qy git build-essential clang curl
RUN curl -L https://src.chromium.org/chrome/trunk/src/build/install-build-deps.sh > /tmp/install-build-deps.sh
RUN chmod +x /tmp/install-build-deps.sh
RUN /tmp/install-build-deps.sh --no-prompt --no-arm --no-chromeos-fonts --no-nacl
RUN rm /tmp/install-build-deps.sh

# Don't build as root.
RUN useradd -m user
USER user
ENV HOME /home/user
WORKDIR /home/user

# Install Chromium's depot_tools.
ENV DEPOT_TOOLS ${HOME}/depot_tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS
ENV PATH $PATH:$DEPOT_TOOLS
RUN echo -e "\n# Add Chromium's depot_tools to the PATH." >> .bashrc
RUN echo "export PATH=\"\$PATH:$DEPOT_TOOLS\"" >> .bashrc


# Install edash packager
RUN gclient config https://www.github.com/google/edash-packager.git --name=src
RUN gclient sync
RUN ninja -d stats -C /home/user/src/out/Release

# clean up
USER root
RUN apt-get remove -y git build-essential clang curl && apt-get autoremove -y && apt-get clean && rm -rf /var/cache/apt/*

# Transparent link
VOLUME  /home/user/src/out/Release/


WORKDIR /home/user/src/out/Release/
ENTRYPOINT ./packager

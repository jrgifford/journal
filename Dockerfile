FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && apt-get install -qy \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-european \
    texlive-science \
    python3-pygments python3 gnuplot ghostscript \
    make git locales sudo \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_GB -c -f UTF-8 -A /usr/share/locale/locale.alias en_GB.UTF-8

# Create a user that can be mapped to host user
RUN groupadd -g 1000 texuser && \
    useradd -u 1000 -g 1000 -m -s /bin/bash texuser && \
    echo 'texuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /data
VOLUME ["/data"]
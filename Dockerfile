# Multi-stage build for optimized LaTeX journal generation
## Stage 1: Minimal builder for user setup (kept small to avoid heavy installs)
FROM ubuntu:20.04 as builder
ENV DEBIAN_FRONTEND=noninteractive

# Create non-root user for security (no heavy packages installed here)
RUN groupadd -r journal && useradd -r -g journal -d /home/journal -m journal

# Set working directory and ownership
WORKDIR /data
RUN chown journal:journal /data

# Stage 2: Runtime stage with minimal footprint
FROM ubuntu:20.04 as runtime
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB:en
ENV LC_ALL=en_GB.UTF-8

# Install only runtime dependencies and locale support
# Includes a fallback to old-releases if standard mirrors are unavailable (20.04 ESM)
RUN set -eux; \
    apt-get update -q || (sed -i 's|http://archive.ubuntu.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list && apt-get update -q); \
    # Install locales first and configure, to avoid TeX post-install failures due to missing locales
    apt-get install -qy --no-install-recommends locales; \
    locale-gen en_GB.UTF-8; \
    update-locale LANG=en_GB.UTF-8; \
    # Now install runtime dependencies
    apt-get install -qy --no-install-recommends \
        texlive-latex-base \
        texlive-latex-recommended \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-fonts-extra \
        texlive-plain-generic \
        texlive-science \
        texlive-extra-utils \
        python3-pygments \
        gnuplot-nox \
        ghostscript \
        make \
        python3; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy user setup from builder
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder --chown=journal:journal /home/journal /home/journal

# Set working directory and user
WORKDIR /data
USER journal

# Define volume mount point
VOLUME ["/data"]

# Default command
CMD ["make"]

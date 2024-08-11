FROM ubuntu:22.04

# Set environment variables for non-interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=UTC

# Set locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create non-root user
ARG USER=appuser
ARG UID=1000
ARG GID=1000
ARG USER_PASSWORD=userpassword
ARG ROOT_PASSWORD=Aa.cbbdft123

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    shellinabox \
    openssh-server \
    vsftpd \
    cron \
    htop \
    vim \
    nano \
    net-tools \
    haveged \
    locales \
    tzdata \
    sudo \
    docker.io \
    git \
    python3 \
    python3-pip \
    && locale-gen en_US.UTF-8 \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && groupadd -g ${GID} ${USER} \
    && useradd -u ${UID} -g ${GID} -m -s /bin/bash ${USER} \
    && echo "${USER}:${USER_PASSWORD}" | chpasswd \
    && echo "root:${ROOT_PASSWORD}" | chpasswd \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Configure FTP
RUN sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf \
    && sed -i 's/#local_enable=YES/local_enable=YES/' /etc/vsftpd.conf \
    && sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf \
    && sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf \
    && echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf \
    && echo "pasv_enable=YES" >> /etc/vsftpd.conf \
    && echo "pasv_min_port=30000" >> /etc/vsftpd.conf \
    && echo "pasv_max_port=31000" >> /etc/vsftpd.conf

# Configure cron job
RUN echo "* * * * * root echo 'cron job running' >> /var/log/cron.log 2>&1" > /etc/cron.d/my-cron-job \
    && chmod 0644 /etc/cron.d/my-cron-job

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Set Shellinabox port\n\
SHELLINABOX_PORT=${PORT:-10000}\n\
\n\
# Start SSH service\n\
service ssh start\n\
\n\
# Start FTP service\n\
service vsftpd start\n\
\n\
# Start cron service\n\
service cron start\n\
\n\
# Start Shellinabox\n\
exec /usr/bin/shellinaboxd -t -s /:LOGIN -p ${SHELLINABOX_PORT} --disable-ssl\n\
' > /root/start.sh \
    && chmod +x /root/start.sh

# Expose Shellinabox port (can be overridden by PORT environment variable)
EXPOSE 10000

# Allow non-root user to use docker.io, git, python3, pip
RUN usermod -aG docker ${USER} && \
    usermod -aG sudo ${USER}

# Use startup script as entrypoint
ENTRYPOINT ["/root/start.sh"]

# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置环境变量以减少交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 设置时区
ENV TZ=UTC

# 设置语言环境
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# 创建非 root 用户
ARG USER=appuser
ARG UID=1000
ARG GID=1000
ARG USER_PASSWORD=userpassword
ARG ROOT_PASSWORD=Aa.cbbdft123

# 安装常用工具、Shellinabox、SSH 服务器和 FTP 服务器，设置语言环境，清理缓存
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

# 配置 SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 配置 FTP
RUN sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf \
    && sed -i 's/#local_enable=YES/local_enable=YES/' /etc/vsftpd.conf \
    && sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf \
    && sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf \
    && echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf \
    && echo "pasv_enable=YES" >> /etc/vsftpd.conf \
    && echo "pasv_min_port=30000" >> /etc/vsftpd.conf \
    && echo "pasv_max_port=31000" >> /etc/vsftpd.conf

# 配置 cron 作业
RUN echo "* * * * * root echo 'cron job running' >> /var/log/cron.log 2>&1" > /etc/cron.d/my-cron-job \
    && chmod 0644 /etc/cron.d/my-cron-job

# 创建启动脚本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# 设置 Shellinabox 端口\n\
SHELLINABOX_PORT=${PORT:-10000}\n\
\n\
# 启动 SSH 服务\n\
service ssh start\n\
\n\
# 启动 FTP 服务\n\
service vsftpd start\n\
\n\
# 启动 cron 服务\n\
service cron start\n\
\n\
# 启动 Shellinabox\n\
exec /usr/bin/shellinaboxd -t -s /:LOGIN -p ${SHELLINABOX_PORT} --disable-ssl\n\
' > /root/start.sh \
    && chmod +x /root/start.sh

# 暴露 Shellinabox 端口（会被 PORT 环境变量覆盖）
EXPOSE 10000

# 使用启动脚本作为入口点
ENTRYPOINT ["/root/start.sh"]

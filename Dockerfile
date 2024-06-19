# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 安装常用工具和Shellinabox
RUN apt-get update && \
    apt-get install -y \
    shellinabox \
    openssh-server \
    cron \
    htop \
    vim \
    nano \
    net-tools \
    haveged \
    locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置 root 用户的密码为 'frepai'
RUN echo 'root:cbbdft123' | chpasswd

# 配置SSH
RUN mkdir /var/run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# 设置默认语言环境
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# 配置cron作业
RUN echo '* * * * * root echo "cron job running" >> /var/log/cron.log 2>&1' > /etc/cron.d/my-cron-job && \
    chmod 0644 /etc/cron.d/my-cron-job && \
    crontab /etc/cron.d/my-cron-job

# 启动cron服务
RUN service cron start

# 暴露 22 和 4200 端口
EXPOSE 22 4200

# 启动Shellinabox和SSH服务
CMD service ssh start && service cron start && /usr/bin/shellinaboxd -t -s /:LOGIN

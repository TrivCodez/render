# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置环境变量以避免潜在的提示问题
ENV DEBIAN_FRONTEND=noninteractive

# 安装常用工具和Shellinabox
RUN apt-get update && \
    apt-get install -y \
    shellinabox \
    openssh-server \
    ufw \
    htop \
    vim \
    nano \
    net-tools \
    haveged \
    rsyslog \
    locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置 root 用户的密码为 'cbbdft123'
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

# 配置防火墙
RUN ufw allow OpenSSH && \
    ufw allow 4200/tcp && \
    ufw --force enable

# 配置Shellinabox
RUN sed -i 's/4200/-p 4200/' /etc/default/shellinabox

# 暴露 22 和 4200 端口
EXPOSE 22 4200

# 启动Shellinabox和SSH服务
CMD service rsyslog start && service ssh start && /usr/bin/shellinaboxd -t -s /:LOGIN

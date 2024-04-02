FROM ghcr.io/msh128/ubuntu-docker-desktop:variant

ENV TZ=Asia/Jakarta
ENV DEBIAN_FRONTEND=noninteractive
ARG VARIANT

RUN apt update --fix-missing \
    && apt-fast install -y \
      aria2 curl dbus-x11 ffmpeg fuse3 htop inotify-tools jq less libchromaprint-tools libdbus-glib-1-2 mediainfo mkvtoolnix nano ncdu novnc openssh-client openssh-server \
      parallel postgresql-client python3-pip python3-websockify qbittorrent-nox rename sudo speedtest-cli sqlite3 tigervnc-standalone-server tigervnc-xorg-extension \
      tmux tzdata ubuntu-wallpapers unzip xfce4-terminal xserver-xorg-video-dummy \
    && apt-fast full-upgrade -y
RUN sed -i 's/tigervncconfig -iconic/#tigervncconfig -iconic/g' /etc/X11/Xtigervnc-session
RUN curl -s https://rclone.org/install.sh | bash
RUN curl -sL -o /usr/local/bin/ttyd $(curl -s 'https://api.github.com/repos/tsl0922/ttyd/releases/latest' | jq -r '.assets[] | select(.name|contains("x86_64")).browser_download_url') \
    && chmod a+x /usr/local/bin/ttyd
RUN mkdir -p /opt/teldrive \
    && curl -sL $(curl -s 'https://api.github.com/repos/divyam234/teldrive/releases/latest' | jq -r '.assets[] | select(.name|contains("linux-amd64")).browser_download_url') | tar xz -C /opt/teldrive teldrive \
    && curl -sLO $(curl -s 'https://api.github.com/repos/divyam234/rclone/releases/latest' | jq -r '.assets[] | select(.name|contains("linux-amd64.zip")).browser_download_url') \
    && chmod a+x /opt/teldrive/teldrive \
    && unzip -qq rclone-*.zip \
    && mv rclone-*/rclone* /opt/teldrive/ \
    && chmod a+x /opt/teldrive/rclone \
    && rm -rf rclone-*
RUN curl -sL 'https://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64' | tar xz -C /opt \
    && chmod a+x /opt/Prowlarr/Prowlarr
RUN curl -fsSL 'https://alist.nn.ci/v3.sh' | bash -s install \
    && mkdir -p /opt/alist/data
RUN mkdir -p /var/lib/pgadmin /var/log/pgadmin \
    && pip install pgadmin4 yt-dlp
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
RUN curl -sLO https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared-linux-amd64.deb \
    && apt install -f \
    && rm cloudflared-linux-amd64.deb
RUN aria2c -q -c 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=linux64&lang=en-US' \
    && tar xjf firefox-*.tar.bz2 -C /opt \
    && ln -s /opt/firefox/firefox /usr/local/bin/firefox \
    && rm firefox-*.tar.bz2 \
    && wget -q https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop -P /usr/local/share/applications
ADD --chmod=755 https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/systemctl3.py /usr/bin/systemctl3.py
ADD --chmod=755 https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/journalctl3.py /usr/bin/journalctl3.py
RUN cp -rf /usr/bin/systemctl3.py /usr/bin/systemctl; cp -rf /usr/bin/journalctl3.py /usr/bin/journalctl; chmod a+x /usr/bin/systemctl* /usr/bin/journalctl*
RUN adduser --disabled-password --gecos '' ubuntu \
    && adduser ubuntu sudo \
    && echo 'ubuntu ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && su - ubuntu -c 'mkdir -p /home/ubuntu/{Desktop,Documents,Music,Pictures,Videos,Downloads}; echo '${VARIANT}' > /home/ubuntu/.desktop_environment' \
    && chown ubuntu:ubuntu -R /var/lib/pgadmin /var/log/pgadmin /opt/alist
RUN for a in autoremove purge clean; do apt $a; done \
    && rm -rf /var/lib/apt/lists/*

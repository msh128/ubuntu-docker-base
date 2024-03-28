FROM ubuntu:latest

ENV TZ=Asia/Jakarta
ARG VARIANT

RUN (apt -qq update \
    && DEBIAN_FRONTEND=noninteractive apt -qq install -y \
      aria2 curl dbus-x11 ffmpeg fuse3 htop inotify-tools jq less libchromaprint-tools mediainfo mkvtoolnix nano ncdu novnc openssh-client openssh-server \
      parallel postgresql-client python3-pip python3-websockify qbittorrent-nox rename sudo sqlite3 tigervnc-standalone-server tigervnc-xorg-extension \
      tmux tzdata unzip xfce4-terminal xserver-xorg-video-dummy \
    && apt -qq full-upgrade -y \
    && case ${VARIANT} in \
        xubuntu-core|ubuntu-mate-core) DEBIAN_FRONTEND=noninteractive apt -qq install -y ${VARIANT}^;; \
        lubuntu-desktop) DEBIAN_FRONTEND=noninteractive apt -qq install -y ${VARIANT} --no-install-recommends;; \
        *) DEBIAN_FRONTEND=noninteractive apt -qq install -y ${VARIANT};; \
      esac) > /dev/null 2>&1
RUN pip install yt-dlp udocker > /dev/null 2>&1
RUN (curl -s https://rclone.org/install.sh | bash) > /dev/null 2>&1
RUN curl -sL -o /usr/local/bin/ttyd $(curl -s 'https://api.github.com/repos/tsl0922/ttyd/releases/latest' | jq -r '.assets[] | select(.name|contains("x86_64")).browser_download_url') \
    && chmod a+x /usr/local/bin/ttyd
RUN mkdir -p /opt/teldrive \
    && curl -sL $(curl -s 'https://api.github.com/repos/divyam234/teldrive/releases/latest' | jq -r '.assets[] | select(.name|contains("linux-amd64")).browser_download_url') | tar xz -C /opt/teldrive teldrive && curl -sLO $(curl -s 'https://api.github.com/repos/divyam234/rclone/releases/latest' | jq -r '.assets[] | select(.name|contains("linux-amd64.zip")).browser_download_url') \
    && chmod a+x /opt/teldrive/teldrive \
    && unzip -qq rclone-*.zip \
    && mv rclone-*/rclone* /opt/teldrive/ \
    && chmod a+x /opt/teldrive/rclone \
    && rm -rf rclone-*
RUN curl -sL 'https://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64' | tar xz -C /opt \
    && chmod a+x /opt/Prowlarr/Prowlarr
RUN aria2c -q -c 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=linux64&lang=en-US' \
    && tar xjf firefox-*.tar.bz2 -C /opt \
    && ln -s /opt/firefox/firefox /usr/local/bin/firefox \
    && rm firefox-*.tar.bz2 \
    && wget -q https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop -P /usr/local/share/applications
RUN sed -i 's/tigervncconfig -iconic/#tigervncconfig -iconic/g' /etc/X11/Xtigervnc-session
ADD --chmod=755 https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/systemctl3.py /usr/bin/systemctl3.py
ADD --chmod=755 https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/journalctl3.py /usr/bin/journalctl3.py
RUN cp -rf /usr/bin/systemctl3.py /usr/bin/systemctl; cp -rf /usr/bin/journalctl3.py /usr/bin/journalctl; chmod a+x /usr/bin/systemctl* /usr/bin/journalctl*
RUN (adduser --disabled-password --gecos '' ubuntu \
    && adduser ubuntu sudo \
    && echo 'ubuntu ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers) > /dev/null 2>&1
RUN su - ubuntu -c 'mkdir -p /home/ubuntu/{Desktop,Documents,Music,Pictures,Videos,Downloads}; \
    udocker pull xhofe/alist:latest; udocker create --name=alist xhofe/alist:latest; \
    udocker pull dpage/pgadmin4:latest; udocker create --name=pgadmin4 dpage/pgadmin4:latest' > /dev/null 2>&1
RUN (for a in autoremove purge clean; do apt -qq $a; done \
    && rm -rf /var/lib/apt/lists/*) > /dev/null 2>&1

CMD ["/sbin/init"]

FROM ubuntu:latest

ENV TZ=Asia/Jakarta

RUN (apt -qq update \
    && DEBIAN_FRONTEND=noninteractive apt -qq install -y \
      aria2 curl ffmpeg fuse3 htop inotify-tools jq less libchromaprint-tools mediainfo mkvtoolnix nano ncdu novnc openssh-client openssh-server \
      parallel postgresql-client python3-pip python3-websockify qbittorrent-nox rename sudo sqlite3 tigervnc-standalone-server tigervnc-xorg-extension \
      tmux tzdata unzip xfce4-terminal xserver-xorg-video-dummy dbus-x11 \
    && apt -qq install -y placeholder_for_desktop_package \
    && apt -qq full-upgrade -y \
    && for a in autoremove purge clean; do apt -qq $a; done) > /dev/null 2>&1 \
    && rm -rf /var/lib/apt/lists/*
RUN pip install yt-dlp udocker > /dev/null 2>&1
RUN (curl -s https://rclone.org/install.sh | bash) > /dev/null 2>&1
RUN curl -sL -o /usr/local/bin/ttyd $(curl -s 'https://api.github.com/repos/tsl0922/ttyd/releases/latest' | jq -r '.assets[] | select(.name|contains("x86_64")).browser_download_url')
RUN mkdir -p /opt/teldrive \
    && curl -sL $(curl -s 'https://api.github.com/repos/divyam234/teldrive/releases/latest' | jq -r '.assets[] | select(.name|contains("linux-amd64")).browser_download_url') | tar xz -C /opt/teldrive teldrive && curl -sLO $(curl -s 'https://api.github.com/repos/divyam234/rclone/releases/latest' | jq -r '.assets[] | select(.name|contains("linux-amd64.zip")).browser_download_url') \
    && unzip -qq rclone-*.zip \
    && mv rclone-*/rclone* /opt/teldrive/ \
    && rm -rf rclone-*
RUN curl -sL 'https://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64' | tar xz -C /opt
RUN aria2c -q -c 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=linux64&lang=en-US' \
    && tar xjf firefox-*.tar.bz2 -C /opt \
    && ln -s /opt/firefox/firefox /usr/local/bin/firefox \
    && rm firefox-*.tar.bz2 \
    && wget https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop -P /usr/local/share/applications
RUN sed -i 's/tigervncconfig -iconic/#tigervncconfig -iconic/g' /etc/X11/Xtigervnc-session
ADD --chmod=755 https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/systemctl3.py /usr/bin/systemctl3.py
ADD --chmod=755 https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/journalctl3.py /usr/bin/journalctl3.py
RUN cp -rf /usr/bin/systemctl3.py /usr/bin/systemctl; cp -rf /usr/bin/journalctl3.py /usr/bin/journalctl; chmod a+x /usr/bin/systemctl* /usr/bin/journalctl*
RUN (adduser --disabled-password --gecos '' ubuntu \
    && adduser ubuntu sudo \
    && echo 'ubuntu ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers) > /dev/null 2>&1
RUN chmod a+x /usr/local/bin/ttyd /opt/teldrive/teldrive /opt/teldrive/rclone /opt/Prowlarr/Prowlarr
RUN su - ubuntu -c 'udocker pull xhofe/alist:latest && udocker create --name=alist xhofe/alist:latest; udocker pull dpage/pgadmin4:latest && udocker create --name=pgadmin4 dpage/pgadmin4:latest' > /dev/null 2>&1

CMD ["/usr/bin/systemctl","default"]

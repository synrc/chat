FROM erlang:24.2.1
RUN apt-get update && apt-get install -y inotify-tools gettext sudo curl mc && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://raw.github.com/synrc/mad/master/mad > mad && chmod +x mad && sudo cp mad /usr/bin/
RUN useradd -m naxim  && echo "maxim:00000" | chpasswd && adduser maxim sudo
RUN echo "Host \tStrictHostKeyChecking no\n" >> /etc/ssh/config
USER maxim
RUN mkdir /home/maxim/.ssh/
RUN touch /home/maxim/.ssh/known_hosts
RUN chown -R maxim:maxim /home/maxim/.ssh
ADD  files/id_rsa      /home/maxim/.ssh/ 
ADD  files/id_rsa.pub  /home/maxim/.ssh/
RUN  chmod 600 ~/.ssh/id_rsa && \
RUN eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa & >/dev/null
RUN ssh-keyscan github.com >> /home/maxim/.ssh/known_hosts
WORKDIR /home/maxim
RUN git clone -b cluster ssh://git@github.com/synrc/chat.git
WORKDIR /home/maxim/chat
RUN rm -f vm.args etc/emq.conf
RUN mad dep
RUN mad cle comp pla
CMD ["/home/maxim/chat/priv/google/kubernetes/kubernetes.sh"]
# emqttd will occupy these port:
# - 1883 MQTT(QUIC) # 8883 MQTT(TCP/TLS)
# - 8083 WS/HTTP    # 8084 WSS/HTTPS
# - 8080 mgmt API   # 18083 dashboard
# - 4369 portmapper # 6000-6999 Erlang/OTP
EXPOSE 1883 8883 8083 8084 8080 8888 18083 4369


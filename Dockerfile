FROM emeraldsquad/alpine-scripting

ENV CF_CLI_VERSION=6.40.1
ENV PCF_SCHEDULER=scheduler-for-pcf-cliplugin-linux32-binary-1.1.0
ENV PCF_AUTOSCALER=autoscaler-for-pcf-cliplugin-linux32-binary-2.0.40


RUN apk add --no-cache python3 py-yaml && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache


RUN wget -q -O - 'https://cli.run.pivotal.io/stable?release=linux64-binary&source=github&version='${CF_CLI_VERSION} \
        | tar -xzf - -C /usr/bin


ADD cf-plugins .

RUN cf install-plugin -f ${PCF_SCHEDULER} \
  && cf install-plugin -f ${PCF_AUTOSCALER} \
  && cf plugins \
  && rm -f ${PCF_SCHEDULER} \
  && rm -f ${PCF_AUTOSCALER}

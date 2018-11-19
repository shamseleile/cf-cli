FROM emeraldsquad/alpine-scripting

ENV CF_CLI_VERSION=6.38.0
ENV PCF_SCHEDULER=scheduler-for-pcf-cliplugin-linux32-binary-1.1.0
ENV PCF_AUTOSCALER=autoscaler-for-pcf-cliplugin-linux32-binary-2.0.40

RUN wget -q -O - 'https://cli.run.pivotal.io/stable?release=linux64-binary&source=github&version='${CF_CLI_VERSION} \
        | tar -xzf - -C /usr/bin


ADD cf-plugins .

RUN cf install-plugin -f ${PCF_SCHEDULER} \
  && cf install-plugin -f ${PCF_AUTOSCALER} \
  && cf plugins \
  && rm -f ${PCF_SCHEDULER} \
  && rm -f ${PCF_AUTOSCALER}
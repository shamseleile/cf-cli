FROM emeraldsquad/alpine-scripting

ARG JMETER_VERSION="5.1.1"

ENV CF_CLI_VERSION=6.40.1
ENV PCF_SCHEDULER=scheduler-for-pcf-cliplugin-linux32-binary-1.1.0
ENV PCF_AUTOSCALER=autoscaler-for-pcf-cliplugin-linux32-binary-2.0.40
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}

ENV JMETER_BIN  ${JMETER_HOME}/bin
ENV MIRROR_HOST http://mirrors.ocf.berkeley.edu/apache/jmeter
ENV JMETER_DOWNLOAD_URL ${MIRROR_HOST}/binaries/apache-jmeter-${JMETER_VERSION}.tgz
ENV JMETER_PLUGINS_DOWNLOAD_URL https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz
ENV JMETER_PLUGINS_FOLDER ${JMETER_HOME}/lib/ext/
ENV JMETER_PLUGINS_LIB_FOLDER ${JMETER_HOME}/lib/
ENV PATH $PATH:$JMETER_BIN

RUN apk add --no-cache python3 py-yaml && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    apk add ca-certificates && \
	  update-ca-certificates && \
	  apk add --update openjdk8-jre tzdata curl unzip bash && \
	  apk add --no-cache nss && \
	  rm -rf /var/cache/apk/* && \
    rm -r /root/.cache && \
    mkdir -p /tmp/dependencies  && \
    curl -L --silent ${JMETER_DOWNLOAD_URL} >  /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz  && \
    mkdir -p /opt  && \
    tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt  && \ 
    rm -rf /tmp/dependencies

RUN wget -q -O - 'https://cli.run.pivotal.io/stable?release=linux64-binary&source=github&version='${CF_CLI_VERSION} \
        | tar -xzf - -C /usr/bin


RUN curl -L --silent https://mvnrepository.com/artifact/kg.apc/jmeter-plugins-casutg/jmeter-plugins-casutg-2.8.jar  -o ${JMETER_PLUGINS_FOLDER}/jmeter-plugins-casutg-2.8.jar

ADD cf-plugins .

RUN cf install-plugin -f ${PCF_SCHEDULER} \
  && cf install-plugin -f ${PCF_AUTOSCALER} \
  && cf plugins \
  && rm -f ${PCF_SCHEDULER} \
  && rm -f ${PCF_AUTOSCALER}
 
COPY  jmeter-plugins/  /${JMETER_PLUGINS_LIB_FOLDER}/
COPY  jmeter-plugins/PluginsManagerCMD.sh  /JMETER_BIN/ 

RUN JMETER_BIN/PluginsManagerCMD.sh install jpgc-casutg




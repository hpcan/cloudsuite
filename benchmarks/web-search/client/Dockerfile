FROM cloudsuite/spark-base:base
MAINTAINER Javier Picorel <javier.picorel@epfl.ch>

ENV FABAN_USER faban

RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends telnet wget tar openjdk-7-jdk \
	&& rm -rf /var/lib/apt/lists/* \
	&& groupadd -r $FABAN_USER  \
	&& useradd -r -g $FABAN_USER $FABAN_USER

ENV BASE_PATH /usr/src
ENV FABAN_HOME $BASE_PATH/faban
ENV PACKAGES_URL http://lsi-www.epfl.ch/parsa
ENV SEARCH_DRIVER_URL $PACKAGES_URL/search.tar.gz
ENV FABAN_PORT 9980
ENV ANT_VERSION 1.9.6
ENV ANT_HOME $BASE_PATH/ant
ENV JAVA_HOME /usr/bin
ENV FABAN_OUTPUT_DIR $BASE_PATH/outputFaban
ENV CLIENT_HEAP_SIZE 2g
ENV DRIVER_DIR $FABAN_HOME/search
ENV POLICY_PATH $DRIVER_DIR/config/security/driver.policy
ENV BENCHMARK_CONFIG $FABAN_HOME/search/deploy/run.xml

ENV SOLR_PORT 8983
ENV SEARCH_DRIVER Ziphian.java
ENV TERMS_FILE terms_ordered
ENV RAMP_UP 90 
ENV RAMP_DOWN 60 
ENV STEADY_STATE 60
ENV SCALE 50
ENV AGENT_ID 1
ENV NUM_AGENTS 1

RUN cd $BASE_PATH \
	&& wget "faban.org/downloads/faban-kit-latest.tar.gz" \
	&& tar -xzf faban-kit-latest.tar.gz 

RUN cd $BASE_PATH \
	&& wget "archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz" \
	&& tar -zxf apache-ant-$ANT_VERSION-bin.tar.gz \
	&& ln -s $BASE_PATH/apache-ant-$ANT_VERSION/ $ANT_HOME 

RUN cd $FABAN_HOME \
	&& wget -O - $SEARCH_DRIVER_URL \
	| tar -xzf - 

RUN cd $FABAN_HOME/search \
	&& sed -i "/faban.home/c\\faban.home=$FABAN_HOME" build.properties \
	&& sed -i "/ant.home/c\\ant.home=$ANT_HOME" build.properties \
	&& sed -i "/faban.url/c\\faban.url=http://localhost:$FABAN_PORT/" build.properties 

#RUN HOST_IP=$(echo `ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`) \
#  && AGENTS=$HOST_IP:$NUM_AGENTS 

#RUN 	chown -R $FABAN_USER:$FABAN_USER $BASE_PATH

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE $FABAN_PORT
#USER $FABAN_USER

ENTRYPOINT ["/entrypoint.sh"]


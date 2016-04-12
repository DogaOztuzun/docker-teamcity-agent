FROM java:8-jre
MAINTAINER Alexander Gorokhov <sashgorokhov@gmail.com>

RUN apt-get install -y unzip git curl

# Install aspnet 1.0.0-beta4
ENV DNX_FEED https://www.myget.org/F/aspnetmaster/api/v2
ENV DNX_USER_HOME /opt/dnx

RUN curl -sSL https://raw.githubusercontent.com/aspnet/Home/7d6f78ed7a59594ce7cdb54a026f09cb0cbecb2a/dnvminstall.sh | DNX_BRANCH=master sh
RUN bash -c "source $DNX_USER_HOME/dnvm/dnvm.sh \
    && dnvm install 1.0.0-beta4 -a default \
    && dnvm alias default | xargs -i ln -s $DNX_USER_HOME/runtimes/{} $DNX_USER_HOME/runtimes/default"

# Install libuv for Kestrel from source code (binary is not in wheezy and one in jessie is still too old)
RUN LIBUV_VERSION=1.8.0 \
    && curl -sSL https://github.com/libuv/libuv/archive/v${LIBUV_VERSION}.tar.gz | tar zxfv - -C /usr/local/src \
    && cd /usr/local/src/libuv-$LIBUV_VERSION \
    && sh autogen.sh && ./configure && make && make install \
    && rm -rf /usr/local/src/libuv-$LIBUV_VERSION \
    && ldconfig

# Update NuGet feeds

RUN mkdir -p ~/.config/NuGet/
RUN curl -o ~/.config/NuGet/NuGet.Config -sSL https://gist.githubusercontent.com/AlexZeitler/a3412a4d4eeee60f8ce8/raw/45b0b5312845099cdf5da560829e75949d44d65f/NuGet.config

ENV PATH $PATH:$DNX_USER_HOME/runtimes/default/bin

ENV SERVER_URL="" \
    AGENT_OWN_ADDRESS="" \
    AGENT_OWN_PORT="9090" \
    AGENT_NAME="" \
    AGENT_DIR="/opt/teamcity_agent"
ENV AGENT_WORKDIR=$AGENT_DIR"/work_dir" \
    AGENT_TEMPDIR=$AGENT_DIR"/temp_dir"

EXPOSE $AGENT_OWN_PORT
VOLUME $AGENT_WORKDIR $AGENT_TEMPDIR
WORKDIR $AGENT_DIR

RUN mkdir /agent-init.d
COPY /setup_docker.sh /agent-init.d/

COPY setup_agent.sh /
CMD /setup_agent.sh && $AGENT_DIR/bin/agent.sh run

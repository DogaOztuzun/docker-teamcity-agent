FROM java:8-jre
MAINTAINER Alexander Gorokhov <sashgorokhov@gmail.com>

RUN apt-get install -y unzip git curl libunwind8 libssl-dev

ENV DNX_USER_HOME /opt/dnx
RUN mozroots --import --sync

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list
RUN apt-get update
RUN apt-get install mono-complete

RUN curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_BRANCH=dev sh && source ~/.dnx/dnvm/dnvm.sh
RUN dnvm upgrade -u
RUN dnvm install latest -r coreclr -u
RUN dnvm use 1.0.0-rc1-update1 -r mono
# Update NuGet feeds

RUN mkdir -p ~/.config/NuGet/
RUN curl -o ~/.config/NuGet/NuGet.Config -sSL https://gist.githubusercontent.com/AlexZeitler/a3412a4d4eeee60f8ce8/raw/45b0b5312845099cdf5da560829e75949d44d65f/NuGet.config

ENV PATH $PATH:$DNX_USER_HOME/runtimes/default/bin
ENV DNX_PATH $PATH:$DNX_USER_HOME/runtimes/default/bin

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

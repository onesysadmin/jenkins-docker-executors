FROM gcr.io/google_appengine/base
MAINTAINER Edvinas Bartkus <edvinas@plateculture.com>

# Prepare for gcloud
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN apt-get update && apt-get install -y -qq --no-install-recommends wget unzip python php5-mysql php5-cli php5-cgi openjdk-7-jre-headless openssh-client python-openssl && apt-get clean

RUN wget https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip && unzip google-cloud-sdk.zip && rm google-cloud-sdk.zip
RUN google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --additional-components app-engine-java app-engine-python app kubectl alpha beta gcd-emulator pubsub-emulator cloud-datastore-emulator app-engine-go bigtable

RUN google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check true
RUN sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' /google-cloud-sdk/lib/googlecloudsdk/core/config.json

RUN mkdir /.ssh
ENV PATH /google-cloud-sdk/bin:$PATH

# expose the port
EXPOSE 8080

# required to make docker in docker to work
VOLUME ["/.config", "/var/lib/docker"]

# default jenkins home directory
ENV JENKINS_HOME /var/jenkins
# set our user home to the same location
ENV HOME /var/jenkins

# set our wrapper
ENTRYPOINT ["/usr/local/bin/docker-wrapper"]
# default command to launch jenkins
CMD java -jar /usr/share/jenkins/jenkins.war

# setup our local files first
ADD docker-wrapper.sh /usr/local/bin/docker-wrapper

# now we install docker in docker - thanks to https://github.com/jpetazzo/dind
# We install newest docker into our docker in docker container
ADD https://get.docker.io/builds/Linux/x86_64/docker-1.6.2 /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker

# for installing docker related files first
RUN echo deb http://archive.ubuntu.com/ubuntu precise universe > /etc/apt/sources.list.d/universe.list
# apparmor is required to run docker server within docker container
RUN apt-get update -qq && apt-get install -qqy wget curl git iptables ca-certificates apparmor

# for jenkins
RUN echo deb http://pkg.jenkins-ci.org/debian binary/ >> /etc/apt/sources.list \
    && wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
RUN apt-get update -qq && apt-get install -qqy jenkins

RUN apt-get update && apt-get install -qy \
  git \
  build-essential \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libpq-dev \
  imagemagick \
  libmagickwand-dev \
  cmake \
  nodejs \
  curl \
  aspell \
  aspell-en \
  wget \
  gzip \
  libgeos-dev

RUN cd /tmp && \
  git clone https://github.com/sstephenson/ruby-build.git && \
  cd ruby-build && \
  ./install.sh && \
  ruby-build 2.3.1 /opt/ruby/2.3.1 && \
  rm -rf /tmp/ruby-build*

ENV PATH=$PATH:/opt/ruby/2.3.1/bin

RUN gem update --system && \
    gem install bundler

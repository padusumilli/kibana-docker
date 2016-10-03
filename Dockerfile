# Build kibana with ThreatTrack branding
FROM centos:6

# Upgrade and install dependencies
RUN yum -y clean all \
  && yum -y distro-sync \
  && yum -y update \
  && yum -y upgrade \
  && yum -y install gcc gcc-c++ patch readline readline-devel zlib zlib-devel curl install libyaml-devel libffi-devel openssl-devel make git wget perl-Digest-SHA zip \
  && yum -y install bzip2 autoconf automake libtool bison iconv-devel install rubygems ruby-devel ruby-json python-setuptools rpm-build openssh-clients openssl-devel

# Install C++ 11
RUN yum install -y centos-release-scl \
  && yum install -y devtoolset-3-gcc devtoolset-3-gcc-c++
ENV PATH /opt/rh/devtoolset-3/root/usr/bin/:$PATH

# Install python2.7
RUN cd /tmp && \
    wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz && \
    tar xvfz Python-2.7.12.tgz && \
    cd Python-2.7.12 && \
    ./configure --prefix=/usr/local && \
    make && \
    make altinstall

# Install setuptools + pip
RUN cd /tmp && \
    wget --no-check-certificate https://pypi.python.org/packages/source/s/setuptools/setuptools-1.4.2.tar.gz && \
    tar -xvf setuptools-1.4.2.tar.gz && \
    cd setuptools-1.4.2 && \
    python2.7 setup.py install && \
    curl https://bootstrap.pypa.io/get-pip.py | python2.7 - && \
    pip install virtualenv

ENV PATH /usr/local/rvm/bin/:/tmp/Python-2.7.12/:$PATH

# install rvm
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 \
  && curl -sSL https://get.rvm.io | bash -s stable --quiet-curl \
  && rvm install 2.0.0 \
  && source /usr/local/rvm/scripts/rvm \
  && /bin/bash -l -c "rvm use --default 2.0.0" \
  && echo "source /usr/local/rvm/scripts/rvm" >> /etc/profile \
  && echo "rvm --default use $RUBY-$RUBY_VERSION" >> /etc/profile \
  && rvm 2.0.0 do gem install fpm -v 1.4.0 \
  && rvm 2.0.0 do gem install pleaserun -v 0.0.21

# Install nodejs
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 4.4.7

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

WORKDIR kibana
CMD source /opt/rh/devtoolset-3/enable && npm install && rvm 2.0.0 do npm run build:ospackages

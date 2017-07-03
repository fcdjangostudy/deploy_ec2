FROM       ubuntu:16.04
MAINTAINER dev@azelf.com

RUN        apt-get -y update
RUN        apt-get install -y python-pip
RUN        apt-get install -y git vim

# pyenv setup
RUN        apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils
RUN        curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
RUN        echo 'export PATH="/root/.pyenv/bin:$PATH"' >> ~/.bash_profile
RUN        echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
RUN        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile
ENV        PATH /root/.pyenv/bin:$PATH

RUN        pyenv install 3.6.1


RUN        apt-get install  -y zsh
RUN        wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN        chsh -s /usr/bin/zsh

RUN        echo 'export PATH="/home/ubuntu/.pyenv/bin:$PATH"' >> ~/.zshrc
RUN        echo 'eval "$(pyenv init -)"' >> ~/.zshrc
RUN        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc


FROM ruby:3.2

# ���|�W�g�����X�V���ˑ����W���[�����C���X�g�[��
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

# ���[�g������webapp�Ƃ������O�ō�ƃf�B���N�g�����쐬�i�R���e�i���̃A�v���P�[�V�����f�B���N�g���j
RUN mkdir /webapp
WORKDIR /webapp

# �z�X�g��Gemfile��Gemfile.lock���R���e�i�ɃR�s�[
ADD Gemfile /webapp/Gemfile
ADD Gemfile.lock /webapp/Gemfile.lock

# bundle install�̎��s
RUN bundle install

# �z�X�g�̃A�v���P�[�V�����f�B���N�g���������ׂăR���e�i�ɃR�s�[
ADD . /webapp

# puma.sock��z�u����f�B���N�g�����쐬
RUN mkdir -p tmp/sockets

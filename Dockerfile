FROM ruby:2.5.1

# リポジトリを更新し依存モジュールをインストール
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

# ルート直下にwebappという名前で作業ディレクトリを作成（コンテナ内のアプリケーションディレクトリ）
RUN mkdir /webapp
WORKDIR /webapp

# ホストのGemfileとGemfile.lockをコンテナにコピー
ADD Gemfile /webapp/Gemfile
ADD Gemfile.lock /webapp/Gemfile.lock

# 環境変数設定
ENV RAILS_ENV="production"
ENV NODE_ENV="production"
ENV RAILS_MASTER_KEY="9e1acc671797572677d11533b34d4529"

# bundle installの実行
RUN bundle install

# ホストのアプリケーションディレクトリ内をすべてコンテナにコピー
ADD . /webapp

# puma.sockを配置するディレクトリを作成
RUN mkdir -p tmp/sockets

# アセットのプリコンパイル
RUN bundle exec rake assets:precompile RAILS_ENV=production

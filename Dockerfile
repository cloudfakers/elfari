FROM ruby:2.3.4

ADD . /opt/elfari
WORKDIR /opt/elfari

RUN bundle install

EXPOSE 4000

CMD ["bundle", "exec", "ruby", "elfari.rb"]

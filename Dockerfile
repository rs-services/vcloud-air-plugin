FROM ruby:2.1-onbuild

ENV APP_ENV production

EXPOSE 8080

CMD ["bundle", "exec", "rails", "server", "-u", "-e", "production", "-p", "8080", "-b", "0.0.0.0"]

FROM ruby:2.1-onbuild

EXPOSE 8080

CMD ["bundle", "exec", "rails", "server", "-u", "-e", "production", "-p", "8080"]

source 'https://rubygems.org'


gem 'rails', '4.2.6'

gem 'rails-api'


gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'thin'
gem 'vcloud-rest', git:'https://github.com/rs-services/vcloud-rest.git',ref:'faa88ddbcfd0c4f9d468811c9a79def4302246cd'

group :development do
    gem 'web-console', '~> 2.0'
end

group :development, :test do
    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
    gem 'byebug'

    # Access an IRB console on exception pages or by using <%= console %> in views

    # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
    gem 'spring'
    gem 'rspec-rails', '~> 3.4'
end

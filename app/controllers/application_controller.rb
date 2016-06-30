class ApplicationController < ActionController::API
  before_filter :authenticate

  def authenticate
        config = YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]
    puts "secret #{request.headers["X-Api-Shared-Secret"]}"
    puts config["api-shared-secret"]
    puts config

    if config["api-shared-secret"] != request.headers["X-Api-Shared-Secret"]
      render text: "api-shared-secret/X-Api-Shared-Secret mismatch error", status: 403
    end
  end
end

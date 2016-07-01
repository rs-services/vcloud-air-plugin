class ApplicationController < ActionController::API
  before_filter :authenticate

  # verify api-shared-secret match Self-Service X-Api-Shared-Secret header
  def authenticate
    config = YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]

    if config["api-shared-secret"] != request.headers["X-Api-Shared-Secret"]
      render text: "api-shared-secret/X-Api-Shared-Secret mismatch error", status: 403
    end
  end
end

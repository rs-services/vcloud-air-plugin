class ServersController < ApplicationController
#  before_filter :create_session
  #before_filter :authenticate_shared_secret


  def create
    begin
      raise "Error: Missing server params" if params[:server].blank?

      server = Server.new(params[:server])
      server = server.create
      server.merge!(href: "http://#{request.env['HTTP_HOST']}#{request.env['PATH_INFO']}/#{server[:id]}")
      Rails.logger.debug "server.create #{server.to_json}"
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      response.headers["Location"] = server[:href]
      render json: server.to_json, status: 201
    rescue => e
      render json: e.message, status: 500
    end
  end

  def destroy
    begin
      raise "Error: Missing server params" if params[:server].blank?

      server = Server.destroy(params[:server][:org],params[:server][:vdc],
      params[:server][:name], params[:id])
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      Rails.logger.debug "server.destroy #{server.to_json}"
      render json: server.to_json, status: 204
    rescue => e
      render json: e.message, status: 500
    end
  end

  def show
    begin
      raise "Error: Missing id param" if params[:id].blank?

      server = Server.find(params[:id])
      server.merge!(href: "http://#{request.env['HTTP_HOST']}#{request.env['PATH_INFO']}/#{params[:id]}")
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      render json: server.to_json, status: 200
    rescue => e
      render json: e.message, status: 500
    end
  end

  private
  # def create_session
  #   config = YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]
  #   session = Session.new(config)
  #   @connection = session.create
  #   raise "unable to get connection: #{connection}" if session.errors.any?
  # end

end

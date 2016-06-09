class ServersController < ApplicationController
  #before_filter :authenticate_shared_secret


  def create
    begin
      raise "Error: Missing server params" if params[:server].blank?

      server = Server.new(params[:server])
      server = server.create
      server.merge!(href: server_path(server[:id]))
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
      raise "Error: Missing id param" if params[:id].blank?

      server = Server.destroy(params[:id])
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
      server.merge!(href: server_path(server[:id]))
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      render json: server.to_json, status: 200
    rescue VCloudClient::UnauthorizedAccess => e
      render nothing: true, status: 404
    rescue => e
      render json: e.message, status: 500
    end
  end

  def stop
    begin
      raise "Error: Missing id param" if params[:id].blank?

      server = Server.stop(params[:id])
      server.merge!(href: server_path(server[:id]))
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      render json: server.to_json, status: 200
    rescue VCloudClient::UnauthorizedAccess => e
      render nothing: true, status: 404
    rescue => e
      render json: e.message, status: 500
    end
  end

  def start
    begin
      raise "Error: Missing id param" if params[:id].blank?

      server = Server.start(params[:id])
      server.merge!(href: server_path(server[:id]))
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      render json: server.to_json, status: 200
    rescue VCloudClient::UnauthorizedAccess => e
      render nothing: true, status: 404
    rescue => e
      render json: e.message, status: 500
    end
  end

  def power_on
    begin
      raise "Error: Missing id param" if params[:id].blank?

      server = Server.power_on(params[:id])
      server.merge!(href: server_path(server[:id]))
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      render json: server.to_json, status: 200
    rescue VCloudClient::UnauthorizedAccess => e
      render nothing: true, status: 404
    rescue => e
      render json: e.message, status: 500
    end
  end

  def power_off
    begin
      raise "Error: Missing id param" if params[:id].blank?

      server = Server.power_off(params[:id])
      server.merge!(href: server_path(server[:id]))
      response.headers["Content-Type"] = "application/vnd.vcloudair.servers+json"
      render json: server.to_json, status: 200
    rescue VCloudClient::UnauthorizedAccess => e
      render nothing: true, status: 404
    rescue => e
      render json: e.message, status: 500
    end
  end

end

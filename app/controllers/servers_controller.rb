class ServersController < ApplicationController
  def create
    begin
      raise "Error: Missing session params" if params[:session].blank?
      raise "Error: Missing server params" if params[:server].blank?

      session = Session.new(params[:session])
      connection = session.create
      raise "unable to get connection: #{connection}" if session.errors.any?

      server = Server.new(params[:server].merge(connection: connection))
      response = server.create
      render json: response.to_json
    rescue => e
      render json: e.message, status: 500
    end
  end

  def destroy
    begin
      raise "Error: Missing session params" if params[:session].blank?
      raise "Error: Missing server params" if params[:server].blank?

      session = Session.new(params[:session])
      connection = session.create
      raise "unable to get connection: #{connection}" if session.errors.any?

      server = Server.destroy(connection, params[:server][:org],params[:server][:vdc],
      params[:server][:name], params[:server][:vm_id])
      render json: server.to_json
    rescue => e
      render json: e.message, status: 500
    end
  end
end

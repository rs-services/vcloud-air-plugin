class ServersController < ApplicationController

  def create
    session = Session.new(params)
    connection = session.create

    if connection
      server = Server.new(paramas)
      response = server.create
      render :json, response.to_json
    end
  end


end

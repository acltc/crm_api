class Api::V1::LeadsController < ApplicationController

  def index
    @leads = Lead.all
    render "index.json.jbuilder"
  end

  def show
    @lead = Lead.find(params[:id])
    render "show.json.jbuilder"
  end

  def create
    @lead = Lead.find_or_create_by(email: params[:email]) do |lead|
      lead.first_name = params[:first_name]
      lead.last_name = params[:last_name]
      lead.phone = params[:phone]
      lead.ip = params[:ip]
      lead.city = params[:city]
      lead.state = params[:state]
      lead.zip = params[:zip]
      lead.created_at = params[:created_at]
      lead.updated_at = params[:updated_at]
    end
    @lead.update(hot: true) unless @lead.connected || @lead.bad_number
    @lead.events.create(name: params[:name], created_at: params[:created_at], updated_at: params[:updated_at])
    if params[:name] == "Finished Application"
      @lead.update(connected: true, hot: false)
    end
    render "show.json.jbuilder"
  end

end

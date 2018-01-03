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
    # A lead is created by someone triggering an "event" on the website in 
    # which they submit information like a name and email address. 
    # If this is the first time this particular person triggered an event,
    # they become a lead, so we store both the lead and the particular
    # event they triggered. If they've triggered an event previously and already
    # become a lead in the past, we just record their new event.
    
    @lead = Lead.find_or_initialize_by(email: params[:email])
    @lead.first_name = params[:first_name] if params[:first_name]
    @lead.last_name = params[:last_name] if params[:last_name]
    @lead.phone = params[:phone] if params[:phone]
    @lead.ip = params[:ip] if params[:ip]
    @lead.city = params[:city] if params[:city]
    @lead.state = params[:state] if params[:state]
    @lead.zip = params[:zip] if params[:zip]
    @lead.created_at = params[:created_at] if params[:created_at]
    @lead.updated_at = params[:updated_at] if params[:updated_at]
    @lead.save

    @lead.events.create(name: params[:name], created_at: params[:created_at], updated_at: params[:updated_at])
    render "show.json.jbuilder"
  end

end

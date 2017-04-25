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
    @lead.events.create(name: params[:name], created_at: params[:created_at], updated_at: params[:updated_at])
    if params[:name] == "Finished Application"
      @lead.update(exclude_from_calling: true)
    end
    create_drip_lead
    render "show.json.jbuilder"
  end

  private

    def create_drip_lead
      client = Drip::Client.new do |c|
        c.api_key = ENV["DRIP_API_KEY"]
        c.account_id = ENV["DRIP_ACCOUNT_ID"]
      end

      client.create_or_update_subscriber(@lead.email, {custom_fields: { first_name: @lead.first_name, cell_phone: @lead.phone, mousetrap: @lead.events.last.name } })
      client.subscribe(@lead.email, 34197704)
    end
end

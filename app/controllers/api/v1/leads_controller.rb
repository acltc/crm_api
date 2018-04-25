class Api::V1::LeadsController < ApplicationController

  def index
    offset = (params[:page].to_i*50) || 0
    puts offset
    if params[:search] && params[:search].length
      @leads = Lead
        .includes(:outreaches)
        .joins(:events)
        .select("leads.*, max(events.created_at) as recent_event_date")
        .where("lower(leads.first_name) LIKE ? OR lower(leads.last_name) LIKE ? OR lower(leads.email) LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
        .group("leads.id")
        .order(params[:sort] + ' ' + params[:direction])
        .limit(50)
        .offset(offset)
    elsif params[:sort]
      @leads = Lead
        .includes(:outreaches)
        .joins(:events)
        .select("leads.*, max(events.created_at) as recent_event_date")
        .group("leads.id")
        .order(params[:sort] + ' ' + params[:direction])
        .limit(50)
        .offset(offset)
    else 
      @leads = Lead
        .includes(:outreaches)
        .joins(:events)
        .select("leads.*, max(events.created_at) as recent_event_date")
        .group("leads.id")
        .order("recent_event_date DESC")
        .limit(50)
        .offset(offset)
    end
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
    
    check_for_spam_id_address = Unirest.get("https://api.apility.net/badip/#{params[:ip]}").code

    if code == 200 # it's spam!
      head :ok
    else 
      @lead = Lead.find_or_initialize_by(email: params[:email])
      @lead.first_name = params[:first_name] if params[:first_name].present?
      @lead.last_name = params[:last_name] if params[:last_name].present?
      @lead.phone = params[:phone] if params[:phone].present?
      @lead.ip = params[:ip] if params[:ip].present?
      @lead.city = params[:city] if params[:city].present?
      @lead.state = params[:state] if params[:state].present?
      @lead.zip = params[:zip] if params[:zip].present?
      @lead.created_at = params[:created_at] if params[:created_at].present?
      @lead.updated_at = params[:updated_at] if params[:updated_at].present?
      @lead.source = params[:source] if params[:source].present?
      @lead.save

      @lead.events.create(name: params[:name], created_at: params[:created_at], updated_at: params[:updated_at])
        

      create_drip_lead
      render "show.json.jbuilder"
    end
  end

  private

    def create_drip_lead
      client = Drip::Client.new do |c|
        c.api_key = ENV["DRIP_API_KEY"]
        c.account_id = ENV["DRIP_ACCOUNT_ID"]
      end

      client.create_or_update_subscriber(@lead.email, {custom_fields: { first_name: @lead.first_name, cell_phone: @lead.phone, mousetrap: @lead.events.last.name } })
      client.subscribe(@lead.email, 13828799)
    end

end

class Api::V1::LeadsController < ApplicationController

  def index
    offset = (params[:page].to_i*50) || 0
    if params[:search] && params[:search].length
      @leads = Lead
        .includes(:outreaches)
        .joins(:events)
        .select("leads.*, max(events.created_at) as recent_event_date")
        .where("lower(leads.first_name) LIKE ? OR lower(leads.last_name) LIKE ? OR lower(leads.email) LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
        .where(spam: false)
        .group("leads.id")
        .order(params[:sort] + ' ' + params[:direction])
        .limit(50)
        .offset(offset)
    elsif params[:sort]
      @leads = Lead
        .includes(:outreaches)
        .joins(:events)
        .select("leads.*, max(events.created_at) as recent_event_date")
        .where(spam: false)
        .group("leads.id")
        .order(params[:sort] + ' ' + params[:direction])
        .limit(50)
        .offset(offset)
    else 
      @leads = Lead
        .includes(:outreaches)
        .joins(:events)
        .select("leads.*, max(events.created_at) as recent_event_date")
        .where(spam: false)
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
    
    # check_for_spam_ip_address = Unirest.get("https://api.apility.net/badip/#{params[:ip]}?token=#{ENV['SPAM_CHECKER_API']}").code

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
        
    # if check_for_spam_ip_address == 200 # it's spam!
      # @lead.update(spam: true)
    # else 
      create_drip_lead
      create_closeio_lead
    # end
    render "show.json.jbuilder"
  end

  private

    def create_drip_lead
      client = Drip::Client.new do |c|
        c.api_key = ENV["DRIP_API_KEY"]
        c.account_id = ENV["DRIP_ACCOUNT_ID"]
      end


      

      if params[:name] == "TLASE" # Think Like a Software Engineer Newsletter
        client.create_or_update_subscriber(@lead.email, {custom_fields: { first_name: @lead.first_name, cell_phone: @lead.phone, mousetrap: @lead.events.last.name } })

        client.subscribe(@lead.email, 843692586)
      elsif params[:name] == "blog" # The Actualize Blog
        client.create_or_update_subscriber(@lead.email, {custom_fields: { first_name: @lead.first_name, cell_phone: @lead.phone, mousetrap: @lead.events.last.name } })
        
        client.subscribe(@lead.email, 10866344)
      # elsif params[:name] == "60-day" # The Sixty Day Challenge
      #   client.subscribe(@lead.email, 188969751)
      # else
      #   client.subscribe(@lead.email, 13828799) Old Drip Campaign Called "Actualize"
      end
    end

    def create_closeio_lead
      lead_details = HTTP.basic_auth(:user => ENV["CLOSEIO_API"], :pass => "").headers({"Content-Type" => "application/json", 'Accept' => 'application/json'}).get("https://app.close.io/api/v1/lead/?query=#{@lead.email}").parse

      if lead_details["total_results"] > 0 # the lead already exists in close.io
        lead_id = lead_details["data"][0]["id"] # find the close.io id for that lead
        if params[:name] == "Finished Application"
          # update their status to "Applied"
          HTTP.basic_auth(:user => ENV["CLOSEIO_API"], :pass => "").headers({"Content-Type" => "application/json", 'Accept' => 'application/json'}).put("https://app.close.io/api/v1/lead/#{lead_id}/", json: { status: "Lead: Applied",
              "custom.lcf_hHk8rnINvBidSayym4UjAxGeCeppsRFF4Hp30i3np4G" => "Yes", "custom.lcf_Sfcy3nEbjCsOuIx6RBWrdSyuOkwZRzUO4eAqjuoWdVR" => params[:name] })
        else
           HTTP.basic_auth(:user => ENV["CLOSEIO_API"], :pass => "").headers({"Content-Type" => "application/json", 'Accept' => 'application/json'}).put("https://app.close.io/api/v1/lead/#{lead_id}/", json: {
              "custom.lcf_Sfcy3nEbjCsOuIx6RBWrdSyuOkwZRzUO4eAqjuoWdVR" => params[:name]})
        end
      else
        HTTP.basic_auth(:user => ENV["CLOSEIO_API"], :pass => "").headers({"Content-Type" => "application/json", 'Accept' => 'application/json'}).post("https://app.close.io/api/v1/lead/", json: {
              name: @lead.email,
              "custom.lcf_8lVNrVx3D39ppNWVtXAiBPsxVMPNe2oRC1BaRX3EQAz" => @lead.events.last.name,
              "custom.lcf_9iTJONvjuBDs24Ruq1H5AcJukPmq0SyelFvaDtAlQt0" => Time.now,
              "custom.lcf_d4q609qhOUdXMIDUCHqKCKQASovF9gF2iOzlPSs0I8I" => @lead.source,
              contacts: [
                  {
                      name: (@lead.first_name || "there"),
                      emails: [
                          {
                              type: "main",
                              email: @lead.email
                          }
                      ],
                      phones: [
                          {
                              type: "cell",
                              phone: @lead.phone
                          }
                      ]
                  }
              ]
              
          })
      end
    end

end

class LeadsController < ApplicationController
  def index
    @leads = Lead.order(created_at: :desc)
    @leads = Lead.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%").order(created_at: :desc) if params[:search]
  end

  def show
    @lead = Lead.find_by(id: params[:id])
  end

  def next
    @lead = Lead.next
    # This page can also be repurposed as the edit page if a specific lead id is provided:
    @lead = Lead.find_by(id: params[:id]) if params[:id]
    redirect_to '/no_leads' unless @lead
  end

  def token
    identity = Faker::Internet.user_name.gsub(/[^0-9a-z_]/i, '')

    capability = Twilio::Util::Capability.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
    capability.allow_client_outgoing ENV['TWILIO_TWIML_APP_SID']
    capability.allow_client_incoming identity
    token = capability.generate
    
    # Generate the token and send to client
    render json: {identity: identity, token: token}
  end

  def voice
    twiml = Twilio::TwiML::Response.new do |r|
      if params['To'] and params['To'] != ''
        r.Dial callerId: ENV['TWILIO_CALLER_ID'] do |d|
          # wrap the phone number or client name in the appropriate TwiML verb
          # by checking if the number given has only digits and format symbols
          if params['To'] =~ /^[\d\+\-\(\) ]+$/
            d.Number params['To']
          else
            d.Client params['To']
          end
        end
      else
        r.Say "Thanks for calling!"
      end
    end
    
    render xml: twiml.text
  end

  def no_leads
  end

  def update
    @lead = Lead.find_by(id: params[:id])
    if @lead.update(lead_params)
      @lead.process
      redirect_to "/"
    else
      flash[:error] = "ERROR: We could not process this lead."
      render :next
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone, :city, :state, :zip, :contacted, :appointment_date, :notes, :connected, :bad_number, :advisor, :location)
  end
end

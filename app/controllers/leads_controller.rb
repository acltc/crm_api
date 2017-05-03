class LeadsController < ApplicationController
  before_action :authenticate_admin!, except: [:token, :voice, :text]

  def index
    @all_leads_active = "active"
    @leads = Lead.where("phone <> ''").order(created_at: :desc)
    @leads = Lead.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%").order(created_at: :desc) if params[:search]
  end

  def edit
    @lead = Lead.find_by(id: params[:id])
  end

  def next
    @outbound_mode_active = "active"
    @lead = Lead.next(current_admin.email)
    @call_mode = true
    if @lead
      render :edit
    else
      redirect_to '/no_leads'
    end
  end

  def update
    @lead = Lead.find_by(id: params[:id])
    if @lead.update(lead_params)
      if params[:lead][:connected] == '1'
        puts '*******************************************'
        puts 'FIRE DRIP CALL'

        client = Drip::Client.new do |c|
          c.api_key = ENV["DRIP_API_KEY"]
          c.account_id = ENV["DRIP_ACCOUNT_ID"]
        end
        client.apply_tag(@lead.email, "contacted")
      end
      # If we're in call mode or we explicity process a lead by clicking on the 'process' checkbox from the edit screen, process and move on to the next lead
      if params[:lead][:call_mode] == "true" || params[:lead][:call_mode] == "1"
        @lead.process
        current_admin.record_progress(@lead)
        redirect_to "/next"
      else # if we're simply updating a lead
        flash[:success] = "Lead saved!"
        redirect_to '/'
      end
    else
      flash[:error] = "ERROR: We could not update this lead."
      render :next
    end
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

  # Make voice calls through the browser:
  def voice
    from_number = params['FromNumber'].blank? ? ENV['TWILIO_CALLER_ID'] : params['FromNumber']
    twiml = Twilio::TwiML::Response.new do |r|
      if params['To'] and params['To'] != ''
        r.Dial callerId: from_number do |d|
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

  # Text from the browser:
  def text
    @client = Twilio::REST::Client.new
    @client.messages.create(
      from: '+17734666919', # Default Twilio number
      to: params[:phone],
      body: params[:body]
    )

    # Send a text to Ben to confirm that text went through:
    @client.messages.create(
      from: '+17734666919', # Default Twilio number
      to: '+17737241128', # Ben's number
      body: "You sent: #{params[:body]}"
    )
    render nothing: true
  end

  def no_leads
  end

  private

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone, :city, :state, :zip, :contacted, :appointment_date, :notes, :connected, :bad_number, :advisor, :location, :first_appointment_set, :first_appointment_actual, :first_appointment_format, :second_appointment_set, :second_appointment_actual, :second_appointment_format, :enrolled_date, :deposit_date, :sales, :collected, :status, :next_step, :rep_notes, :exclude_from_calling, :meeting_type, :meeting_format)
  end
end

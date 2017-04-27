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
    @lead = Lead.next
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
      # If we're in call mode, process and move on to the next lead
      if params[:lead][:call_mode]
        @lead.process
        redirect_to "/"
      else # if we're simply updating a lead
        flash[:success] = "Lead saved!"
        redirect_to '/leads'
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

  def text
    @client = Twilio::REST::Client.new
    @client.messages.create(
      from: '+17734666919',
      to: params[:phone],
      body: params[:body]
    )

    @client.messages.create(
      from: '+17734666919',
      to: '+17737241128',
      body: "You sent: #{params[:body]}"
    )
    render nothing: true
  end

  def no_leads
  end

  private

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone, :city, :state, :zip, :contacted, :appointment_date, :notes, :connected, :bad_number, :advisor, :location, :first_appointment_set, :first_appointment_actual, :first_appointment_format, :second_appointment_set, :second_appointment_actual, :second_appointment_format, :enrolled_date, :deposit_date, :sales, :collected, :status, :next_step, :rep_notes, :exclude_from_calling)
  end
end

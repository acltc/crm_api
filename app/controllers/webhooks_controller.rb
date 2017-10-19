class WebhooksController < ApplicationController
  def incoming_voice
    twiml = Twilio::TwiML::Response.new do |r|
      if params['From'] and params['From'] != ''
        r.Dial callerId: params['From'] do |d|
          d.Number ENV['EMPLOYEE_PHONE_NUMBER']
        end
      else
        r.Say "Thanks for calling!"
      end
    end

    render xml: twiml.text
  end

  def incoming_text
    # This code looks up the incoming phone number in our database and
    # retrieves the lead if found:
    begin
      standard_phone = Phoner::Phone.parse(params['From'], country_code: '1').to_s
      @lead = Lead.find_by(standard_phone: standard_phone) if standard_phone
    rescue
      # this will throw an exception if the given phone number is very off
    end
    extra_info = @lead.email if @lead

    @client = Twilio::REST::Client.new
    @client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: ENV['EMPLOYEE_PHONE_NUMBER']
      body: "Message from #{params['From']}: #{params['Body']}. Extra Info: #{extra_info}"
    )
  end

end

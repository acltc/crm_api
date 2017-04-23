class WebhooksController < ApplicationController
  def incoming_voice
    twiml = Twilio::TwiML::Response.new do |r|
      if params['From'] and params['From'] != ''
        r.Dial callerId: params['From'] do |d|
          d.Number '+17733048862'
        end
      else
        r.Say "Thanks for calling!"
      end
    end
    
    render xml: twiml.text
  end

  def incoming_text
    
  end
end

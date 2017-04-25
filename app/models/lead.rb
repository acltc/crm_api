class Lead < ApplicationRecord
  has_many :events

  before_save :standardize_phone

  def self.next
    if Rails.env.development?
      # In development, we deal with leads from all time:
      return Lead.where(contacted: false).where(bad_number: false).where(exclude_from_calling: false).where("phone <> ''").order(:created_at).last
    else
      # In production, we are currently only dealing with leads from a certain date
      return Lead.where(contacted: false).where(bad_number: false).where(exclude_from_calling: false).where("phone <> ''").where('created_at > ?', '2017-04-21 19:06:25').order(:created_at).last
    end    
  end

  def process
    if should_be_left_a_message
      text
    end
  end

  def text
    @client = Twilio::REST::Client.new
    @client.messages.create(
      from: '+17734666919',
      to: self.phone,
      body: 'Hi - this is Ben from Actualize. Do you have a minute to chat?'
    )
  end

  private

  def standardize_phone
    begin
      self.standard_phone = Phoner::Phone.parse(self.phone, country_code: '1').to_s
    rescue 
      # this will throw an exception if the given phone number is very off
    end
  end

  def should_be_left_a_message
    # We tried dialing a good number but didn't reach them:
    self.contacted && !self.bad_number && !self.connected
  end
end

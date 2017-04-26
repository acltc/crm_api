class Lead < ApplicationRecord
  has_many :events

  before_save :standardize_phone

  def self.next
    Lead.where(hot: true).where(exclude_from_calling: false).where("phone <> ''").order(:updated_at).last  
  end

  def process
    self.update(process_time: Time.now, hot: false)
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

  def full_name
    "#{self.first_name} #{self.last_name}"
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

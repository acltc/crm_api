class Lead < ApplicationRecord
  has_many :events

  before_save :standardize_phone

  def self.next
    # We first look for a hot lead. This is defined by a lead who was either never dialed (contacted) or someone who we dialed but never reached and triggered a new event since we tried to dial them:
    hot_lead = Lead.where(hot: true).where(exclude_from_calling: false).where("phone <> ''").order(:updated_at).last
    return hot_lead if hot_lead
    # If we can't find a hot lead, we return people who have only been dialed once but we've never reached:
    return Lead.where(number_of_dials: 1).where(exclude_from_calling: false).where(connected: false).where(bad_number: false).where("phone <> ''").order(:updated_at).last
  end

  def process
    self.update(process_time: Time.now, hot: false, contacted: true, number_of_dials: self.number_of_dials + 1)
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

  def processed_within_minutes
    return nil unless self.process_time
    number_of_seconds = self.process_time - self.created_at
    return (number_of_seconds / 60).to_i
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

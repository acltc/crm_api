class Lead < ApplicationRecord
  has_many :events

  def self.next;
    # In production, we are currently only dealing with leads from a certain date
    Lead.where(contacted: false).where(bad_number: false).where('created_at > ?', '2017-04-21 19:06:25').order(:created_at).last
    # In development, we deal with leads from all time:
    Lead.where(contacted: false).where(bad_number: false).order(:created_at).last if Rails.env.development?
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

  def should_be_left_a_message
    # We tried dialing a good number but didn't reach them:
    self.contacted && !self.bad_number && !self.connected
  end
end

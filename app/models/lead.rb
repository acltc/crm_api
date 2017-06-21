class Lead < ApplicationRecord
  has_many :events

  before_save :standardize_phone

  attr_accessor :call_mode

  def self.next(admin_email=nil)
    if admin_email == "rena@actualize.co"
      return Lead.where(old_lead: false).where(exclude_from_calling: false).where(contacted: false).where(bad_number: false).where('enrolled_date is null').where("phone <> ''").where("events.name = 'Started Application'").order(:updated_at).last
    elsif admin_email == "zev@actualize.co"
      return Lead.where("number_of_dials < 2").where(old_lead: true).where(hot: false).where(exclude_from_calling: false).where(connected: false).where(bad_number: false).where('enrolled_date is null').where("phone <> ''").order(:updated_at).last
    else # Ben
      Lead.joins(:events).where("events.name = 'Tour'").where(appointment_date: nil).where(connected: false).where("number_of_dials < 3").where(exclude_from_calling: false).where("phone <> ''").where(bad_number: false).order(:updated_at).last
      # We first look for a hot lead. This is defined by a lead who was either never dialed (contacted) or someone who we dialed but never connected with and they triggered a new event since we last dialed them them:
      # ORIGINAL BEN: 

      #hot_lead = Lead.where(hot: true).where(exclude_from_calling: false).where(connected: false).where('enrolled_date is null').where("phone <> ''").order(:updated_at).last
      #return hot_lead if hot_lead
      # If we can't find a hot lead, we return people who have only been dialed once but we've never reached:
      #return Lead.where(number_of_dials: 1).where(exclude_from_calling: false).where(connected: false).where(bad_number: false).where('enrolled_date is null').where("phone <> ''").order(:updated_at).last
    end
  end

  # This gets called when a call-converter processes a lead while in "Outbound Mode"
  def process
    # A lead becomes "cold" once processed. "contacted" is our term for processed. We also record that we've made another dial to this lead:
    self.update(hot: false, contacted: true, number_of_dials: self.number_of_dials + 1)

    # Record the process time only the first time the lead is processed:
    self.update(process_time: Time.now) unless self.process_time

    # For those we set an appointment with:
    if self.appointment_date
      # Send a calendar invite to the lead:
      # This feature is commented out since it's not complete right now:
      # CalendarInvitesMailer.appointment(self).deliver_now

      # Mark lead as connected in case the call-converter forgot to:
      self.update(connected: true)
    end

    # Leave a text message for certain people
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

  # Reset a lead to as if it's brand new. This is useful for manual testing.
  def reset
    self.update(hot: true, contacted: false, connected: false, exclude_from_calling: false, appointment_date: nil, advisor: nil, number_of_dials: 0)
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

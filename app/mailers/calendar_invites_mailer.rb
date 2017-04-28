class CalendarInvitesMailer < ApplicationMailer
  def appointment(lead)
    @lead = lead

    # Generate the calendar invite
    ical = Icalendar::Calendar.new
    ical.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(@lead.appointment_date)
      # the default calendar invite is for 1 hour, so we don't need to set an endtime
      e.summary     = "Actualize Meeting"
      e.description = "Appointment with our Actualize Admissions Advisor"
    end
    ical.publish

    # Add the .ics as an attachment
    attachments['event.ics'] = { mime_type: 'application/ics', content: ical.to_ical }

    mail(from: "jaywngrw@gmail.com", to: @lead.email, subject: 'Actualize Appointment')
  end
end

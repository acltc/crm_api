class WelcomeMailer < ApplicationMailer
  default from: 'admissions@actualize.co'

  def welcome_email(lead)
    @lead = lead
    mail(to: @lead.email, subject: 'Welcome to Actualize!')
  end
end

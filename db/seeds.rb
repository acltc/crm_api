# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

contacted = [true, false]
event_name = ['fb_form', 'footer_form', 'tutorials', 'tour', 'ebook', 'curriculum']
100.times do
  Lead.create(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.email,
    phone: Faker::PhoneNumber.phone_number,
    city: Faker::Address.city,
    state: Faker::Address.state,
    zip: Faker::Address.zip,
    ip: Faker::Internet.ip_v4_address,
    contacted: contacted.sample,
    appointment_date: Faker::Date.between(2.days.ago, 1.month.from_now)
  )
  Event.create(
    name: event_name.sample,
    lead_id: Lead.last.id
  )
end
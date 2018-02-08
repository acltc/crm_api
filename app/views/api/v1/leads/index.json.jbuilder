json.array!  @leads.each do |lead|
  json.(lead, :id, :first_name, :last_name, :email, :phone, :appointment_date, :notes, :recent_event_date, :outreaches)
end
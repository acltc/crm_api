json.(@lead, :id, :first_name, :last_name, :email, :phone, :ip, :city, :state,
:zip, :contacted, :appointment_date)
json.events @lead.events, :id, :lead_id, :name
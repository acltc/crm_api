namespace :crm_api do
  desc 'Import lead tracker data from CSV to CRM API'
  task :import_lead_data => :environment do
    CSV.foreach('/users/ryanmcmahon/desktop/leads_copy.csv', :headers => true) do |row|
      # Lead.create(row.to_hash.slice(*%w[created_at updated_at city first_name notes phone email]))
      @lead = Lead.find_or_create_by(email: row['email']) do |lead|
        lead.created_at = row['created_at']
        lead.updated_at = row['updated_at']
        lead.city = row['city']
        lead.first_name = row['first_name']
        lead.notes = row['notes']
        lead.phone = row['phone']
      end
      @lead.events.create(name: row['name'], created_at: row['created_at'], updated_at: row['updated_at'])
    end
  end
end
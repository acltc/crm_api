class AddSourceToLeads < ActiveRecord::Migration[5.0]
  def change
  	add_column :leads, :source, :string
  end
end

class AddSpamToLead < ActiveRecord::Migration[5.0]
  def change
    add_column :leads, :spam, :boolean, default: false
  end
end

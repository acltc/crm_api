class Lead < ApplicationRecord
  has_many :events

  def self.next
    Lead.where(contacted: false).where(bad_number: false).where('created_at < ?', '2017-04-21 19:06:25').order(:created_at).last
  end
end

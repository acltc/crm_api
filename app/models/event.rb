class Event < ApplicationRecord
  default_scope { order(created_at: :desc) }
  belongs_to :lead
end

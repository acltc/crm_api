class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :daily_progress_logs
  has_one :setting


  after_create :create_setting
  def create
    Setting.create(admin_id: id)
  end

  def record_progress(lead)
    log = DailyProgressLog.find_or_create_by(admin_id: self.id, date: Date.today)
    log.increment(:processed)
    log.increment(:connects) if lead.connected
    log.increment(:sets) if lead.appointment_date
    log.save
  end
end

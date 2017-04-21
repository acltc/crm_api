class LeadsController < ApplicationController
  def index
    @leads = Lead.order(created_at: :desc)
    @leads = Lead.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%").order(created_at: :desc) if params[:search]
  end

  def show
    @lead = Lead.find_by(id: params[:id])
  end

  def next
    @lead = Lead.next
    # This page can also be repurposed as the edit page if a specific lead id is provided:
    @lead = Lead.find_by(id: params[:id]) if params[:id]
    redirect_to '/no_leads' unless @lead
  end

  def no_leads
  end

  def update
    @lead = Lead.find_by(id: params[:id])
    @lead.update(lead_params)
    redirect_to "/"
  end

  private

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone, :city, :state, :zip, :contacted, :appointment_date, :notes, :connected, :bad_number)
  end
end

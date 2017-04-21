class LeadsController < ApplicationController
  def index
    @leads = Lead.all
  end

  def show
    @lead = Lead.find_by(id: params[:id])
  end

  def next
    @lead = Lead.next
    redirect_to '/no_leads' unless @lead
  end

  def no_leads
  end

  def edit
    @lead = Lead.find_by(id: params[:id])
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

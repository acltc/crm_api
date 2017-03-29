class LeadsController < ApplicationController
  def index
    @leads = Lead.all
    render "index.json.jbuilder"
  end

  def show
    @lead = Lead.find(params[:id])
    render "show.json.jbuilder"
  end
end

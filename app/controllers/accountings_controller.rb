class AccountingsController < ApplicationController
  before_filter :prepare_parent

  authorize_resource

  def index
    @search = @project.accountings.search(params[:search])
    @accountings = @search.all

    @past_work = - @project.entries.sum(:duration) / 60.0 * @project.wage
    @expected_work = - (@project.rpl || 0) * @project.wage

    # Project Return = cash-in - cash-out - past work - expected work
    @project_return = @search.sum(:amount) + @past_work + @expected_work

    # Profitability = (project return) / (cash-in) * 100
    cash_in = @search.where(:positive => true).sum(:amount)
    @project_profitability = 0.0
    if cash_in > 0
      @project_profitability = 100.0 * @project_return / @search.where(:positive => true).sum(:amount)
    end
  end

  def create
    @accounting = @project.accountings.build(params[:accounting])

    if @accounting.save
      redirect_to project_accountings_url(@project), :notice => 'Accounting position successfully created.'
    else
      render :action => 'new'
    end
  end

  def new
    @accounting = @project.accountings.build
  end

  def edit
    @accounting = @project.accountings.find(params[:id])
  end

  def update
    @accounting = @project.accountings.find(params[:id])
    if @accounting.update_attributes(params[:accounting])
      if params[:accounting][:delete_document]
        @accounting.document = nil
        @accounting.save
      end
      flash[:notice] = 'Successfully updated accounting position.'
      redirect_to project_accountings_url(@project)
    else
      render :action => 'edit'
    end
  end

  def destroy
    accounting = Accounting.find(params[:id])
    accounting.destroy
    flash[:notice] = 'Successfully destroyed accounting.'
    redirect_to project_accountings_url(@project)
  end

  protected

  def prepare_parent
    @project = Project.find(params[:project_id])
  end
end

class Admin::EnterpriseController < ApplicationController
  layout 'admin'

  before_action :find_enterprise, :authorized_user?

  def show
    @states     = Locations::UsState::NAME_IDS.map(&:first)
    @accounts   = Account.all
    @marketplace_accounts = Account.by_role("Marketplace Owner")
  end

  def account_create
    create_tenant = Transactions::CreateAccount.new
    result = create_tenant.call(account_create_params)

    if result.success?
      flash[:notice] = "Account was created successfully."
    else
      flash[:error]  = result.failure[:errors].first
    end
    redirect_to admin_enterprise_url(current_account.enterprise)
  end

  def tenant_create
    create_tenant = Transactions::CreateTenant.new
    result = create_tenant.with_step_args(fetch: [enterprise: @enterprise]).call(tenant_params)
    if result.success?
      flash[:notice] = "Successfully created #{result.success.owner_organization_name}"
    else
      flash[:error]  = result.failure[:errors].to_a.join(" ").humanize
    end
    redirect_to action: :show, id: params[:enterprise_id]
  end

  def benefit_year_create
     benefit_year = ::Enterprises::BenefitYear.all.where(calendar_year: params["admin"]["benefit_year"])
     if benefit_year.present?
       flash[:error] = "Benefit Year is already present"
     else
       new_benefit_year = @enterprise.benefit_years.new(expected_contribution: params["enterprises_enterprise"]["value"], calendar_year: params["admin"]["benefit_year"], description: '')
       if new_benefit_year.valid?
         if new_benefit_year.save
           flash[:notice] = "Successfully updated"
         else
           flash[:error]  = new_benefit_year.errors.messages
         end
       else
         flash[:error]  = new_benefit_year.errors.messages
       end
     end
     redirect_to admin_enterprise_path(params["enterprise_id"])
  end

  def benefit_year_update
    update_benefit_year = Transactions::UpdateBenefitYear.new
    result = update_benefit_year.call(by_update_params)
    if result.success?
      flash[:notice] = "Successfully updated"
    else
      flash[:error]  = result.failure[:errors].first
    end
    redirect_to admin_enterprise_path(params["enterprise_id"])
  end

  def make_benefit_year_active
    current_benefit_years = @enterprise.benefit_years.where(:id.nin => [params["benefit_year"]])
    current_benefit_years.present? ? current_benefit_years.map { |by| by.make_inactive } : nil
    @enterprise.benefit_years.find(params["benefit_year"]).make_active
    flash[:notice] = "Successfully updated Benefit Year"
    redirect_to admin_enterprise_path(params["enterprise_id"])
  end

  def show_plan_premium_on_client_result
    show_in_client = params["enterprises_enterprise"]["show_plan_calculation_in_client_ui"]
    @enterprise.update(show_plan_calculation_in_client_ui: show_in_client)
    flash[:notice] = "Update Client UI"
    redirect_to admin_enterprise_path(params["enterprise_id"])
  end

  def purge_hra
    result = ::Transactions::PurgeHra.new.call
    if result.success?
      flash[:notice] = 'Successfully purged HRA database.'
    else
      flash[:error] = result.failure[:errors].first
    end
    redirect_to admin_enterprise_path(params["enterprise_id"])
  end

  private

  def find_enterprise
    @enterprise = ::Enterprises::Enterprise.first
  end

  def authorized_user?
    authorize @enterprise, :can_modify?
  end

  # TODO: refactor all the below methods accordingly.
  def by_update_params
    # by_update_params = {expected_contribution: 0.0922, calendar_year: 2021, benefit_year_id: ::Enterprises::BenefitYear.first.id}
    params.permit!
    params.to_h
  end

  def by_create_params
    # by_create_params = {expected_contribution: 0.0974, calendar_year: 2022, id: ::Enterprises::Enterprise.first.id}
    params.permit!
    params.to_h
  end

  def account_create_params
    # account_create_params = {:email=>"asjdb@jhbs.com", password: "Abcd!1234"}
    params.permit!
    params.to_h
  end

  # filter tenant params
  def tenant_params
    # tenant_params = {key: :ma, owner_organization_name: 'MA Marketplace', account_email: "asjdb@jhbs.com"}
    key = Locations::UsState::NAME_IDS.select { |v| v[0] == params[:admin][:state] }[0][1]
    {
      key: key.downcase,
      owner_organization_name: params[:tenant][:value],
      account_email: params[:admin][:account]
    }
  end
end

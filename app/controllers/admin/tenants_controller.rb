class Admin::TenantsController < ApplicationController
  layout 'admin'
  protect_from_forgery except: [:fetch_locales, :edit_translation, :update_translation, :delete_language]

  before_action :find_tenant, :authorized_user?

  def show
  end

  def update
    result = Transactions::UpdateTenant.new.call({tenant: @tenant, tenant_params: tenant_params})

    if result.success?
      flash[:notice] = 'Successfully updated marketplace settings'
    else
      flash[:error]  = 'Something went wrong.'
    end

    redirect_to admin_tenant_path(id: @tenant.id, tab_name: params[:id]+"_profile")
  end

  def upload_logo
  end

  def features_show
  end

  def features_update
    result = Transactions::UpdateTenant.new.call({tenant: @tenant, tenant_params: tenant_params})

    if result.success?
      flash[:notice] = 'Successfully updated marketplace settings'
    else
      flash[:error]  = 'Something went wrong.'
    end

    redirect_to action: :features_show, id: params[:tenant_id], tab_name: params[:tenant_id]+"_features"
  end

  def translations_show
    @translation_entity = Transactions::ConstructTranslation.new.with_step_args(build: [@tenant, :show]).call(params).value!
  end

  def fetch_locales
    @translation_entity = Transactions::ConstructTranslation.new.with_step_args(build: [@tenant, :fetch_locales]).call(params).value!

    respond_to do |format|
      format.js { render partial: 'source_translations'}
    end
  end

  def edit_translation
    @translation_entity = Transactions::ConstructTranslation.new.with_step_args(build: [@tenant, :edit_translation]).call(params).value!

    respond_to do |format|
      format.js { render partial: 'edit_translation'}
    end
  end

  def update_translation
    @translation_entity  = Transactions::ConstructTranslation.new.with_step_args(build: [@tenant, :update_translation]).call(params).value!
    @translation_entity.editable_translation.value = params['translation']['value']

    if @translation_entity.editable_translation.save
      @messages = { success: 'Successfully updated translation.' }
    else
      @messages = { error: 'Something went wrong.' }
    end
  end

  def plan_index
    @tenant = ::Tenants::Tenant.find(params.permit!['tenant_id'])
    @products = @tenant.products.all
    @years = [@enterprise.benefit_years.where(is_active: true).pluck('calendar_year')]
  end

  def upload_plan_data
    params.permit!
    result = Transactions::SerffTemplateUpload.new.call(params.to_h)
    if result.success?
      flash[:notice] = 'Successfully uploaded plans'
    else
      flash[:error] = result.failure[:errors].first
    end

    redirect_to admin_tenant_plan_index_path(params[:tenant_id], tab_name: params[:tenant_id]+"_plans")
  end

  def plans_destroy
    result = ::Transactions::PlansDestroy.new.call(params)

    if result.success?
      flash[:notice] = 'Successfully destroyed plans'
    else
      flash[:error] = result.failure[:errors].first
    end

    redirect_to admin_tenant_plan_index_path(params[:id], tab_name: params[:id]+"_plans")
  end

  def delete_language
    supported_languages = @tenant.supported_languages
    supported_languages.options.where(:id => BSON::ObjectId.from_string(params['lang_id'])).delete
  end

  private

  def find_tenant
    tenant_id = params[:tenant_id] || params[:id]
    @tenant = Tenants::Tenant.find(tenant_id)
    @enterprise = @tenant.enterprise
  end

  def authorized_user?
    authorize @tenant, :can_modify?
  end

  def tenant_params
    params.require(:tenants_tenant).permit(
      :owner_organization_name,
      sites_attributes: [
        :id,
        options_attributes: [
          :id, :value, :supported_languages,
          child_options_attributes: [
            :id, :value,
            child_options_attributes: [:id, :value]
          ]
        ],
        features_attributes: [
          :id,
          options_attributes: [
            :id, :value,
            child_options_attributes: [
              :id, :value,
              child_options_attributes: [:id, :value]
            ]
          ]
        ]
      ]
    )
  end
end

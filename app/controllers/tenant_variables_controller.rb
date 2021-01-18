class TenantVariablesController < ApplicationController
  before_action :set_tenant_variable, only: [:show, :edit, :update, :destroy]

  # GET /tenant_variables
  # GET /tenant_variables.json
  def index
    @tenant_variables = TenantVariable.all
  end

  # GET /tenant_variables/1
  # GET /tenant_variables/1.json
  def show
  end

  # GET /tenant_variables/new
  def new
    @tenant_variable = TenantVariable.new
  end

  # GET /tenant_variables/1/edit
  def edit
  end

  # POST /tenant_variables
  # POST /tenant_variables.json
  def create
    @tenant_variable = TenantVariable.new(tenant_variable_params)

    respond_to do |format|
      if @tenant_variable.save
        format.html { redirect_to @tenant_variable, notice: 'Tenant variable was successfully created.' }
        format.json { render :show, status: :created, location: @tenant_variable }
      else
        format.html { render :new }
        format.json { render json: @tenant_variable.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenant_variables/1
  # PATCH/PUT /tenant_variables/1.json
  def update
    respond_to do |format|
      if @tenant_variable.update(tenant_variable_params)
        format.html { redirect_to @tenant_variable, notice: 'Tenant variable was successfully updated.' }
        format.json { render :show, status: :ok, location: @tenant_variable }
      else
        format.html { render :edit }
        format.json { render json: @tenant_variable.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenant_variables/1
  # DELETE /tenant_variables/1.json
  def destroy
    @tenant_variable.destroy
    respond_to do |format|
      format.html { redirect_to tenant_variables_url, notice: 'Tenant variable was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tenant_variable
      @tenant_variable = TenantVariable.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tenant_variable_params
      params.require(:tenant_variable).permit(:name, :value)
    end
end

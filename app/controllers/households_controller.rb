class HouseholdsController < ApplicationController
  skip_after_action :verify_authorized, only: [:new, :create, :join]

  def new
    @household = Household.new
  end

  def create
    @household = Household.new(household_params)

    if @household.save
      current_user.update!(household: @household)
      redirect_to new_financial_profile_path, notice: "Foyer créé avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @household = current_household
    authorize @household
  end

  def edit
    @household = current_household
    authorize @household
  end

  def update
    @household = current_household
    authorize @household

    if @household.update(household_params)
      redirect_to household_path, notice: "Foyer mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Rejoindre un foyer existant via token d'invitation
  def join
    household = Household.find_by(invitation_token: params[:token])

    if household.nil?
      redirect_to root_path, alert: "Lien d'invitation invalide."
    elsif household.full?
      redirect_to root_path, alert: "Ce foyer est déjà complet."
    else
      current_user.update!(household: household)
      redirect_to dashboard_path, notice: "Vous avez rejoint le foyer #{household.name} !"
    end
  end

  private

  def household_params
    params.require(:household).permit(:name)
  end
end

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_household

  def current_household
    current_user&.household
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  def require_household!
    unless current_household
      redirect_to new_household_path, alert: "Veuillez d'abord créer votre foyer."
    end
  end

  def user_not_authorized
    redirect_back fallback_location: root_path, alert: "Vous n'êtes pas autorisé à effectuer cette action."
  end
end

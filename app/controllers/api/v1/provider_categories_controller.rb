class Api::V1::ProviderCategoriesController < ApplicationController
  skip_before_action :authenticate_client, only: [:index, :show]
  
  def index
    categories = ProviderCategory.active.ordered.includes(:category_fields)
    render json: ProviderCategorySerializer.format_categories(categories)
  end

  def show
    category = ProviderCategory.active.find_by(slug: params[:id])
    if category
      render json: ProviderCategorySerializer.format_category(category)
    else
      render json: { error: 'Category not found' }, status: :not_found
    end
  end

  def create
    # Super admin only
    authenticate_user!
    unless current_user&.role == 'super_admin'
      render json: { error: 'Unauthorized' }, status: :forbidden
      return
    end

    category = ProviderCategory.new(category_params)
    if category.save
      render json: ProviderCategorySerializer.format_category(category), status: :created
    else
      render json: { error: category.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    # Super admin only
    authenticate_user!
    unless current_user&.role == 'super_admin'
      render json: { error: 'Unauthorized' }, status: :forbidden
      return
    end

    category = ProviderCategory.find_by(slug: params[:id])
    if category&.update(category_params)
      render json: ProviderCategorySerializer.format_category(category)
    else
      render json: { error: 'Category not found or could not be updated' }, status: :unprocessable_entity
    end
  end

  private

  def category_params
    params.require(:provider_category).permit(:name, :description, :is_active, :display_order)
  end
end 
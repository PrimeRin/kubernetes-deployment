class UsersController < ApplicationController
  def index
    users = User.all
    render json: users
  end

  def show
    user = User.find(params[:id])
    render json: user
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'User not found' }, status: :not_found
  end
end

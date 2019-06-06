class AddressesController < ApplicationController

  def create
    @address = Address.new(address_params)
    @address.user = User.find(params[:user_id])
    @address.save
  end

  private

  def address_params
    params.require(:address).permit(:number, :suite, :district, :city, :state, :zipcode)
  end
end

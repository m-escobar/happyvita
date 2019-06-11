class ActivitiesController < ApplicationController
  before_action :set_activity, except: [:index, :new_event, :new_challenge, :create]

  def index
    if params[:query].present?
      sql_query = " \
        activities.title @@ :query \
        OR activities.description @@ :query \
        OR addresses.district @@ :query \
        OR addresses.city @@ :query \
      "
      @activities = Activity.joins(:address).where(sql_query, query: "%#{params[:query]}%").where('confirmed = true')
      if current_user != nil && current_user.bookings != []
        @user_bookings = current_user.bookings
      end
    else
      @activities = Activity.where('confirmed = true')
      if current_user != nil && current_user.bookings != []
        @user_bookings = current_user.bookings
      end
    end
    if current_user != nil
      u_act = current_user.interests.collect { |interest| interest.activities }.flatten.uniq
      @join = @activities & u_act
      @rest = @activities - @join
    else
      @join = []
      @rest = @activities
    end
  end

  def show
    @activity_address_id = @activity.address_id

    @activity_address = Address.find(@activity_address_id)

    @markers_activity = [lat: @activity_address.latitude, lng: @activity_address.longitude]

  end

  def new_event
    @activity = Activity.new
  end

  def new_challenge
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.owner = current_user
    raise

    if @activity.event?  then
      save_msg = "Evento criado com sucesso!"
    else
      @activity.address = Address.first
      save_msg = "Desafio criado com sucesso!"
    end
    if @activity.save
      redirect_to @activity, notice: "#{save_msg}"

    else
      if @activity.event? then
        render :new_event
      else
        render :new_challenge
      end
    end
  end

  def edit_event
    if current_user == @activity.owner
      render :edit_event
    else
      redirect_to @activity, notice: 'Este evento não foi criado por você.'
    end
  end

  def edit_challenge
    if current_user == @activity.owner
      # raise
      render :edit_challenge
    else
      raise
      redirect_to @activity, notice: 'Este desafio não foi criado por você.'
    end
  end

  def update
    @activity.update(activity_params)
    if @activity.save
        redirect_to @activity, notice: 'Atividade editada com sucesso.'
    else
      if activity.event? then
        render :edit_event
      else
        render :edit_challenge
      end
    end
  end

  def cancel
    @activity.confirmed = false
    # @activity.update(cancel_params)
    if @activity.save
        redirect_to @activity, notice: 'Atividade cancelada com sucesso.'
    else
        render :edit
    end
  end

  private
  def set_activity
      @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :event, :group, :event_date,
                                      :photo, :capacity, :confirmed, :address_id, interest_ids:[], activity_interest_id:[])
  end

  def cancel_params
    params.require(:activity).permit(:confirmed)
    #falta :address
  end
end

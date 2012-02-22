##
# The Measurement service facilitates posting and retrieving Safecast Measurements.
# @url /api/measurements
# @topic Measurements
#
class Api::MeasurementsController < Api::ApplicationController
  
  before_filter :authenticate_user!, :only => [:create, :update]
  respond_to :html, :only => :create
  
  ##
  # List all of the *measurement* resources in the Safecast database.  There are a lot of measurements in
  # the system (on the order of millions), so something this general may not actually be what you want.
  #
  # @url [GET] /api/measurements
  #
  # @argument [Integer] user_id Indicate that results should only include measurements created by this user
  #   This can be provided manually, or by calling [GET] /api/users/:id/measurements
  # @argument [Integer] page Results are paginated automatically.  Default is page 1.
  # @argument [Integer] page_size Number of devices to include in one page.  Default is 10.
  #
  def index
    if params[:map_id].present?
      @map = Map.find(params[:map_id])
    end
    if params[:user_id].present?
      @user = User.find params[:user_id]
    end
    if @map
      respond_with @map.measurements.page(params[:page])
    elsif @user
      respond_with @user.measurements.page(params[:page])
    else
      respond_with Measurement.all(params[:page])
    end
  end
  
  ##
  # Retrieve the *measurement* resource indicated by the provided id.
  #
  # @url [GET] /api/measurements/:id
  #
  # @argument [Integer] user_id Indicate that results should only include measurements created by this user
  #   This can be provided manually, or by calling [GET] /api/users/:id/measurements
  # @argument [Integer] page Results are paginated automatically.  Default is page 1.
  # @argument [Integer] page_size Number of devices to include in one page.  Default is 10.
  #
  def show
    if params[:withHistory].present? and params[:withHistory]
      measurements = Measurement.where("id = #{params[:id]} OR original_id = #{params[:id]}")
      respond_with @result = measurements
    else
      measurement = Measurement.most_recent(params[:id])
      respond_with @result = measurement
    end
  end
  
  def update
    measurement = Measurement.find(params[:id])
    new_measurement = measurement.revise(params[:measurement])
    
    # respond_with typically doesn't pass the resource for PUT, but since we're being non-destructive, our PUT actually returns a new resource
    # see: https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/5199-respond_with-returns-on-put-and-delete-verb#ticket-5199-14
    respond_with @result = new_measurement, :status => :created
  end
  
  def add_to_map
    @map = Map.find params[:map_id]
    @measurement = Measurement.new(params[:measurement])
    @map.measurements<< @measurement
    respond_with @measurement, :location => [:api, @measurement]
  end
  
  def create
    @map = Map.find params[:map_id] if params[:map_id].present?
    @measurement = Measurement.new(params[:measurement])
    @measurement.user = current_user
    Measurement.transaction do
      @measurement.save
      @measurement.original_id = @measurement.id
      @measurement.save
    end
    @map.measurements<< @measurement if @map   #this could be done by calling add_to_map, but that seems misleading
    respond_with @result = @measurement, :location => [:api, @measurement]
  end
  
end

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  def default_url_options(options={})
    logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { :locale => I18n.locale }
  end
  def index
    @messages = MessagesController.get_message_list(params)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
    end
  end
  def about
  end
  def privacy
  end
  
  def commands
  end
  
  def create_user
    p=params[:user]
    if p[:lat] && p[:lon]
      @user = User.new(p.merge({:active=>false}))
    else
      res=Geocoder.search(p[:location])
      if res
        lat,lon = res[0].coordinates
        @user = User.new(p.merge({:lat=>lat,:lon=>lon,:active=>false}))
      end
    end

    if @user.present? && @user.save
      $outbound_flocky.message $app_num,"You have been signed up for safehood. To confirm and receive messages, text '#confirm' to this number",@user.phone
    end
    
    redirect_to :action=>:index
  end

end
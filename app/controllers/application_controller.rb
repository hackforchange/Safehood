class ApplicationController < ActionController::Base
  protect_from_forgery
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
  
  def signup_user
    res=Geocoder.search(address)
    if res
      lat,lon = res[0].coordinates
      @user = User.new(:phone=>params[:phone],:location=>location,:lat=>lat,:lon=>lon,:active=>false)
    end
    
    if @user.present? && @user.save
      $outbound_flocky.message $app_num,"You have been signed up for safehood. To confirm and receive messages, text '#confirm' to this number",params[:phone]
    end
    
    redirect_to :action=>:index
  end

end
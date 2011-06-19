class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml
  def self.get_message_list(params)
    Message.safe_fields.paginate(:page=>params[:page],:order=>"created_at DESC")
  end
  
  def index
    @messages = self.class.get_message_list(params)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
      format.json  { render :json => @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message = Message.safe_fields.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # GET /messages/new
  # GET /messages/new.xml
  def new
    @message = Message.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(params[:message])

    respond_to do |format|
      if @message.save
        format.html { redirect_to(@message, :notice => 'Message was successfully created.') }
        format.xml  { render :xml => @message, :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def receive
    params[:incoming_number] = $1 if params[:incoming_number]=~/^1(\d{10})$/
    params[:origin_number] = $1 if params[:origin_number]=~/^1(\d{10})$/
    
    commands = [["signup"],["unsubscribe"],["removeme","unsubscribe"],["change[\w_]*address","change_address"],["help"],["nyan"],["num"],["mute"],["unmute"]]
    commands.each do |c|
      pattern = c.first
      function_name = "handle_#{c.last}".to_sym
      if match = params[:message].match(/^#?#{pattern}:?(.*)/i)
        self.send(function_name,match.to_a.last.strip, params[:origin_number])
        render :text=>"sent", :status=>202
        return
      end
    end

    #not signup, regular message
    @user = User.find_by_phone(params[:origin_number])

    if @user.nil?
      #if they're not signed up, tell them to subscribe first
      message "Hi! Thanks for your message. If you'd like to stay in touch with whats going on in your neighborhood, please text back signup: and put your street address afterwards. Thanks!", params[:origin_number]
      @message = Message.create(:message=>params[:message],:phone=>params[:origin_number])
      render :text=>"sent", :status=>202
      return
    end
    
    #we have a regular message, with a user
    @message = Message.new(:user=>@user,:location=>@user.location,:lat=>@user.lat,:lon=>@user.lon,:message=>params[:message],:phone=>params[:origin_number])
    
    if @message.save
      #send message out to everyone in range
      nearby_phones = @user.nearby_users.map(&:phone)
      message @message.message, nearby_phones #TODO: format date
    else
      message "SORRY_ERROR_TEXT", params[:origin_number]
    end
    
    #return a 202 to tropo
    render :text=>"sent", :status=>202
  end
  
  def voice
    transcript_json = JSON.parse(request.body.read)
    identifier = transcript_json['result']['identifier']
    transcript = transcript_json['result']['transcription']
    params[:message] = transcript
    params[:origin_number] = identifier
    receive
    
  end
  
  private
  
  def require_signup(number,response="You aren't signed up with this phone number. text '#signup' with your address to sign up")
    @user=User.find_by_phone(number)
    message response, number if @user.nil?
    @user
  end
  
  def handle_signup(message, number)
  #TODO: do signup process
    address=message
    res=Geocoder.search(address)
    
    if User.find_by_phone(number)
      message "You're already signed up! you can text \"changeaddress: \" to change your address.", number
      return
    end
    
    if res.empty?
      message "Sorry, we couldn't find that where that is. Please make sure you include the city or zip code", number
      return
    end
    
    lat,lon = res[0].coordinates
    @user = User.new(:phone=>number,:location=>address,:lat=>lat ,:lon=>lon , :radius=>'0.5', :active=>true)
    
    unless @user.save
      message "Sorry, there was an error with signup", number
      return
    end
    
    #update and send recent backlogged messages
    backlog = Message.backlogged(number)
    signup_message = "Thanks for signing up!"

    if backlog.length > 0
      nearby_phones = @user.nearby_users.map(&:phone)

      backlog.each do |message|
        message.update_attributes(:user=>@user,:location=>@user.location,:lat=>@user.lat,:lon=>@user.lon)
        message.save
        message "sent at #{message.created_at}: #{message.message}", nearby_phones #TODO: format date
      end

      signup_message += ", #{backlog.length} backlogged messages sent out"
    end
    
    message signup_message, number
  end
  
  def handle_unsubscribe(message, number)
    return unless require_signup number
    
    @user.destroy
    message "You have been removed from the system", number
  end
  
  def handle_change_address(message,number)
    return unless require_signup number
    
    address=message
    res=Geocoder.search(address)
    
    if res.empty?
      message "Sorry, we couldn't find that where that is. Please make sure you include the city or zip code", number
      return
    end
    
    lat,lon = res[0].coordinates
    @user.update_attributes(:lat=>lat,:lon=>lon,:location=>address)
    
    unless @user.save
      message "Sorry, there was an error with changing", number
      return
    end
    
    message "Address changed!", number
  end
  
  def handle_help(message,number)
    message "available commands: #changeaddress, #removeme, #signup, #help, #num, #mute, #unmute"
  end
  
  def handle_nyan(message,number)
    message ":3", number
  end
  
  def handle_num(message,number)
    return unless require_signup(number)
    count = @user.nearby_users.count
    message "Messages from your location will reach #{helper.pluralize(count,'member')}",number
  end
  
  def handle_mute(message,number)
    return unless require_signup number
    @user.update_attribute(:active,false)
    message "You have been muted. You will receive no further messages. You can text '#unmute' to resume",number
  end
  
  def handle_unmute(message,number)
    return unless require_signup number
    @user.update_attribute(:active,true)
    message "You have been unmuted. You will begin receiving messages again", number
  end
    
  def message(msg,number)
    puts "sending '#{msg}' to #{number}"
    $outbound_flocky.message $app_phone, msg, number
  end
  
end

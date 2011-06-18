class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml
  def index
    @messages = Message.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message = Message.find(params[:id])

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

    
    if params[:message] =~ /^signup:/
      #TODO: do signup process

      #update and send recent backlogged messages
      backlog = Message.backlogged(params[:incoming_number])

      if backlog.length > 0
        nearby_phones = @user.nearby_users.map(&:phone)

        backlog.each do |message|
          message.update_attributes(:user=>@user,:location=>@user.location,:lat=>@user.lat,:lon=>@user.lon)
          message.save
          $outbound_flocky.message $app_phone, "sent at #{message.created_at}: #{message.message}", nearby_phones #TODO: format date
        end

        $outbound_flocky.message $app_phone, "#{backlog.length} backlogged messages sent out", @user.phone
      end

      return
    end

    #not signup, regular message
    @user = User.find_by_phone(params[:origin_number])

    if @user.nil?
      #if they're not signed up, tell them to subscribe first
      $outbound_flocky.message $app_phone, "WELCOME_SIGNUP_TEXT", params[:origin_number]
      @message = Message.create(:message=>params[:message])
      return
    end
    
    #we have a regular message, with a user
    @message = Message.new(:user=>@user,:location=>@user.location,:lat=>@user.lat,:lon=>@user.lon,:message=>params[:message])
    
    if @message.save
      #send message out to everyone in range
      nearby_phones = @user.nearby_users.map(&:phone)
      $outbound_flocky.message $app_phone, message.message, nearby_phones #TODO: format date
    else
      $outbound_flocky.message $app_phone, "SORRY_ERROR_TEXT", params[:origin_number]
    end
    
    #return a 202 to tropo
    render :text=>"sent", :status=>202
  end

end

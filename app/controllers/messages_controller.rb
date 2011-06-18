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

    @user = User.find_by_phone(params[:origin_number])
    
    if @user.nil?
      #if they're not signed up, tell them to subscribe first
      $outbound_flocky.message "WELCOME_SIGNUP_TEXT", params[:origin_number]
      return
    end
    
    @message = Message.new(:user=>@user,:location=>@user.location,:lat=>@user.lat,:lon=>@user.lon,:message=>params[:message])
    
    if @message.save
      #send message out to everyone in range
      @user.nearby_users.each do |u|
        $outbound_flocky.message params[:message], u.phone
      end
    else
      $outbound_flocky.message "SORRY_ERROR_TEXT", params[:origin_number]
    end
    
    #return a 202 to tropo
    render :text=>"sent", :status=>202
  end
  
end

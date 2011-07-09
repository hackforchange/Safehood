class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml
  def self.get_message_list(params)
    m=Message.safe_fields
    if params[:bbox]
      arr = JSON.parse(params[:bbox]) unless params[:bbox].is_a? Array
      m=m.boundbox(*arr)
    end
    m=m.textsearch(params[:q]) if params[:q]
    m=m.where("created_at >= ?", params[:date_min]) if params[:date_min]
    m=m.where("created_at <= ?", params[:date_max]) if params[:date_max]
    params[:per_page] = params[:per_page].nil? ? Message.per_page : [params[:per_page].to_i,1000].min
    m.paginate(:page=>params[:page],:per_page=>params[:per_page],:order=>"created_at DESC")
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
    
    commands = [["signup"],["unsubscribe"],["removeme","unsubscribe"],["change[\s_]*address","change_address"],["help"],["nyan"],["num"],["mute"],["unmute"],["confirm"],["crime"]]
    commands.each do |c|
      pattern = c.first
      function_name = "handle_#{c.last}".to_sym
      if match = params[:message].match(/^#?#{pattern}:?(.*)/i)
        self.send(function_name,match.to_a.last.strip, params[:origin_number])
        render :text=>"sent", :status=>202
        return
      end
    end
    
    if m=params[:message].match(/^#\w*/)
      message "Sorry, unrecognized command '#{m[0]}'. Text #help for valid commands",params[:origin_number]
      return
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
    params[:message] = "voice transcription: " + transcript
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
      message "Sorry, we couldn't find where that is. Please make sure you include the city or zip code", number
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
  
  def handle_confirm(message,number)
    return unless require_signup(number)
    @user.update_attribute(:active,true)
    message "Thanks for signing up!", number
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
    message "available commands: #changeaddress, #removeme, #signup, #help, #num, #mute, #unmute", number
  end
  
  def handle_nyan(message,number)
    message ":3", number
  end
  
  def helper
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::TextHelper
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
  
  # Crimespotter stuff goes after here
  def handle_crime(address,number)
    res=Geocoder.search(address)
    # did we get a readable address?
    if res.empty?
      message "Sorry, we couldn't find where that is. Please make sure you include the city or zip code", number
      return
    # awesome, we've got an address.
    else
      # want reports from the last month
      end_date = Date.today
      begin_date = end_date.prev_month
      lat,lon = res[0].coordinates
      point = Geokit::LatLng.new(lat,lon)
      # by default, get crime for within 1km of location
      b = Geokit::Bounds.from_point_and_radius(point,1,:units=>:km)
      baseUrl = "http://oakland.crimespotting.org/crime-data?format=json&bbox=" + b.sw.lng.to_s + "," + b.sw.lat.to_s + "," + b.ne.lng.to_s + "," + b.ne.lat.to_s + "&dstart=" + begin_date.to_s + "&dend=" + end_date.to_s
      url = URI.parse(baseUrl)
      json_response = JSON.parse(Net::HTTP.get_response(url).body)
      crimes = json_response["features"]
      # 18 chars
      crime_report = "Crime last month: "
      crimes_by_type = {}
      crimes.each do |crime|
        # if we haven't seen this type of crime yet, add to hash and set count to 1
        crime_type = crime["properties"]["crime_type"]
        unless crimes_by_type[crime_type]
          crimes_by_type[crime_type] = 1
        # if we have seen it, increase the count
        else
          crimes_by_type[crime_type] = crimes_by_type[crime_type] + 1
        end
      end
      sorted_crime_types = crimes_by_type.sort_by { |x, y| [ -y, x] }
      x = 0
      while x < sorted_crime_types.length
          crime_type = sorted_crime_types[x]
          # we want to make sure serious crimes appear first
          if crime_type.first == "MURDER" or crime_type.first == "AGGRAVATED ASSAULT" or crime_type.first == "ROBBERY" or crime_type.first == "BURGLARY"
              summary = crime_type.last.to_s + " " + crime_type.first + "  "
              crime_report << summary
              # remove the record from the list
              sorted_crime_types.delete_at(x)
          end
          x = x + 1
      end
      while sorted_crime_types[0]
        type = sorted_crime_types.shift
        summary = type.last.to_s + " " + type.first + "  "
        # 141 minus 19 char for remainder message
        if crime_report.length + summary.length < 122
          crime_report << summary
        # if it isn't going to fit...
        else
          remainder = type.last
          # go through the rest of the list
          while sorted_crime_types[0]
            remaining_type = sorted_crime_types.shift
            remainder = remainder + remaining_type.last
          end
          crime_report << remainder.to_s + " other incidents"
          break
        end
      end
#       print crime_report
      message crime_report,number
    end
  end
end
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
end
%w(sinatra data_mapper haml sinatra/flash sinatra-authentication).each { |lib| require lib }

enable :sessions

class Note
  include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :complete, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end

configure do
  DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/recall.db")
  DataMapper.finalize.auto_upgrade!
  DataMapper.auto_migrate!
  use Rack::Session::Cookie, :secret => 'superdupersecret'
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

get '/' do
  @notes = Note.all :order => :id.desc  # Retrieve all the notes from the database
  @title = 'All Notes'
  if @notes.empty?
    flash.now[:error] = 'No notes found. Add your first below.'
  end
  haml :home
end

post '/' do
  n = Note.create(:content => params[:content], :created_at => Time.now, :updated_at => Time.now)
  if n.save
    redirect '/', flash[:notice] = 'Note created successfully.'
  else
    redirect '/', flash[:error] = 'Failed to save note.'
  end
end

get '/:id' do
  @note = Note.get params[:id]
  @title = "Edit note ##{params[:id]}"
  if @note
    haml :edit
  else
    redirect '/', flash[:error] = "Can't find that note."
  end
end

put '/:id' do
  n = Note.get params[:id]
  unless n
    redirect '/', flash[:error] = "Can't find that note."
  end
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  if n.save
    redirect '/', flash[:notice] = 'Note updated successfully.'
  else
    redirect '/', flash[:error] = 'Error updating note.'
  end
end

get '/:id/delete' do
  @note = Note.get params[:id]
  @title = "Confirm deletion of note ##{params[:id]}"
  if @note
    haml :delete
  else
    redirect '/', flash[:error] = "Can't find that note."
  end
end

delete '/:id' do
  n = Note.get params[:id]
  if n.destroy
    redirect '/', flash[:notice] = "Note deleted successfully."
  else
    redirect '/', flash[:error] = "Error deleting note."
  end
end

get '/:id/complete' do
  n = Note.get params[:id]
  unless n
    redirect '/', flash[:error] = "Can't find that note."
  end
  n.complete = n.complete ? 0 : 1 # flip it
  n.updated_at = Time.now
  if n.save
    if n.complete
      redirect '/', flash[:notice] = "Note marked as complete."
    else
      redirect '/', flash[:notice] = "Note marked as uncomplete."
    end
  else
    redirect '/', flash[:error] = "Error marking note as complete."
  end
end

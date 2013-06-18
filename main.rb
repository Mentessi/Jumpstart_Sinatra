require './song'
require './sinatra/auth'
require 'sinatra'
require 'slim'
require 'sass'
require 'sinatra/flash'
require 'pony'
require 'v8'
require 'coffee-script'
require 'sinatra/reloader' if development?



configure :development do
	DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
	set :email_address => 'smtp.gmail.com',
      :email_user_name => 'Mentessi',
      :email_password => 'secret',
      :email_domain => 'localhost.localdomain'
end

configure :production do 
	DataMapper.setup(:default, ENV['DATABASE_URL'])
	set :email_address => 'smtp.sendgrid.net',
	:email_user_name => ENV['SENDGRID_USERNAME'],
	:email_password => ENV['SENDGRID_PASSWORD'],
	:email_domain => 'heroku.com'
end

before do
	set_title
end

helpers do 
	def css(*stylesheets)
		stylesheets.map do |stylesheet|
			"<link href=\"/#{stylesheet}.css\" media=\"screen, projection\"rel=\"stylesheet\" />"
		end.join
	end

	def current?(path='/')
		(request.path==path || request.path==path+'/') ? "current" :nil
	end

	def set_title
		@title ||= "Songs by Sinatra"
	end

end


get '/styles.css' do
	scss :styles 
end

get('/javascripts/application.js') do
	coffee :application
end

get '/' do 
	slim :home
end

get '/about' do
	@title = "all about this website"
	slim :about
end

get '/contact' do
	@title = "conact shizzle"
	slim :contact
end


not_found do 
	slim :not_found
end

#Contact stuff----------

post '/contact' do 
	send_message
	flash[:notice] = "Thank you for your message. We'll be in touch soon."
	redirect to('/')
end

def send_message
	Pony.mail(
		:from 				=> params[:name] + "<" + params[:email] + ">",
		:to 					=> 'mentessi@gmail.com',
		:subject			=> params[:name] + " has contacted you",
		:body					=> params[:message] + params[:email],
		:port 				=> '587',
		:via 					=> :smtp,
		:via_options 	=> {
			:address							=> 'smtp.gmail.com',
			:port									=> '587',
			:enable_starttls_auto	=> true,
			:user_name						=> 'mentessi',
			:password							=> 'secret',
			:authentication				=> :plain,
			:domain								=> 'localhost.localdomain'
		})
end


#song methods -----------------------#

module SongHelpers

	def find_songs
		@songs = Song.all
	end

	def find_song
		Song.get(params[:id])
	end

	def create_song
		@song = Song.create(params[:song])
	end

end

helpers SongHelpers


get '/songs' do 
	@songs = find_songs
	slim :songs
end

get '/songs/new' do 
	protected!
	@song = Song.new
	slim :new_song
end

get '/songs/:id' do 
	@song = find_song
	slim :show_song
end

post '/songs' do 
	flash[:notice] = "Song successfully added" if create_song
	redirect to("/songs/#{@song.id}")
end

get '/songs/:id/edit' do
	protected! 
	@song = find_song
	slim :edit_song
end

put '/songs/:id' do
	protected!
	song = find_song
	if song.update(params[:song])
		flash[:notice] = "Song sucessfully updated!"
	end
	redirect to("/songs/#{song.id}")
end

delete '/songs/:id' do
	protected! 
	if find_song.destroy
		flash[:notice] = "Song deleted"
	end
	redirect to('/songs')
end


post '/songs/:id/like' do 
	@song = find_song
	@song.likes = @song.likes.next
	@song.save
	redirect to"/songs/#{@song.id}" unless request.xhr?
	slim :like, :layout => false
end









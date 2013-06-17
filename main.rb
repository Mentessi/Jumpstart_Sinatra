require './song'
require 'sinatra'
require 'slim'
require 'sass'
require 'sinatra/flash'
require 'sinatra/reloader' if development?

configure do 
	enable :sessions
	set :username, 'frank'
	set :password, 'sinatra'
end

configure :development do
	DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

configure :production do 
	DataMapper.setup(:default, ENV['DATABASE_URL'])
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


get '/login' do 
	slim :login
end

post '/login' do
	if params[:username] == settings.username && params[:password] == settings.password
		session[:admin] = true
		redirect to('/songs')
	else
		slim :login
	end
end

get '/logout' do
	session.clear
	redirect to('/login')
end

get '/styles.css' do
	scss :styles 
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
	halt(401,'Not Authorized') unless session[:admin]
	@song = Song.new
	slim :new_song
end

get '/songs/:id' do 
	@song = find_song
	slim :show_song
end

post '/songs' do 
	create_song
	redirect to("/songs/#{@song.id}")
end

get '/songs/:id/edit' do 
	@song = find_song
	slim :edit_song
end

put '/songs/:id' do
	song = find_song
	song.update(params[:song])
	redirect to("/songs/#{song.id}")
end

delete '/songs/:id' do 
	find_song.destroy
	redirect to('/songs')
end

#flash message -------

post '/songs' do 
	flash[:notice] = "Song successfully added" if create_song
	redirect to("/songs/#{@song.id}")
end






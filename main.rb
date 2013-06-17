require './song'
require 'sinatra'
require 'slim'
require 'sass'
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

helpers do 
	def css(*stylesheets)
		stylesheets.map do |stylesheet|
			"<link href=\"#{stylesheet}.css\" media=\"screen, projection\"rel=\"stylesheet\" />"
		end.join
	end

	def current?(path='/')
		(request.path==path || request.path==path+'/') ? "current" :nil
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

get '/songs' do 
	@songs = Song.all
	slim :songs
end


not_found do 
	slim :not_found
end

get '/songs/new' do 
	halt(401,'Not Authorized') unless session[:admin]
	@song = Song.new
	slim :new_song
end

get '/songs/:id' do 
	@song = Song.get(params[:id])
	slim :show_song
end

post '/songs' do 
	song = Song.create(params[:song])
	redirect to("/songs/#{song.id}")
end

get '/songs/:id/edit' do 
	@song = Song.get(params[:id]) 
	slim :edit_song
end

put '/songs/:id' do
	song = Song.get(params[:id])
	song.update(params[:song])
	redirect to("/songs/#{song.id}")
end

delete '/songs/:id' do 
	Song.get(params[:id]).destroy
	redirect to('/songs')
end


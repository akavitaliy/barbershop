#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/contrib'
require 'pony'
require 'sqlite3'

def get_db
	db = SQLite3::Database.new 'barber.db'	
	db.results_as_hash = true
	return db
end

def  is_barbers_exist? db, name
	db.execute('select * from Barbers where name=?', [name]).length > 0
end

def seed_db db, barbers 
	
		barbers.each do	|barber|
			if !is_barbers_exist? db, barber
				db.execute 'insert into Barbers (name) values (?)', [barber]
			end	
		end	
	
end

configure do
	db = get_db
	db.execute 'CREATE TABLE IF NOT EXISTS "Users"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" TEXT,
      "phone" TEXT,
      "datestamp" TEXT,
      "barber" TEXT,
      "color" TEXT
    )'
	
	db.execute 'CREATE TABLE IF NOT EXISTS "Contacts"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" TEXT,
      "email" TEXT,
      "message" TEXT
	)'  

	db.execute 'CREATE TABLE IF NOT EXISTS "Barbers"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "name" TEXT      
	)' 

	seed_db db, ['Jessie Pinkman', 'Walter WHite', 'Guse Fring', 'Mike Ehrmatraut']

end

get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School!!!</a>"			
end

get '/about' do
	@error = 'Произошла ошибка!'
	erb :about
end

get '/visit' do
	erb :visit
end

get '/contact' do
	erb :contact
end

get '/showusers' do
	db = get_db
	@dbusers = db.execute 'select * from Users order by id DESC'
	erb :showusers
end

post '/visit' do
	@username = params[:username]
	@phone = params[:phone]
	@datetime = params[:datetime]
	@barber = params[:barber]
	@colors = params[:colors]

	hh = {:username => "Введите имя", :phone => "Введите телефон", :datetime => "Введите дату"}

	hh.each do |key,value|
		if params[key] == ''
			@error = hh[key]
			return erb :visit
		end
	end

	db = get_db
	db.execute 'insert into Users (username, phone, datestamp, barber, color) values (?,?,?,?,?)', [@username, @phone, @datetime, @barber, @colors]

	f = File.open "./public/users.txt", "a"
	f.write "Имя: #{@username}, Телефон: #{@phone}, Время записи: #{@datetime}, Парикмахер: #{@barber}, Цвет: #{@colors}\n"
	f.close

	erb @error = 'Произошла ошибка!'

end

post "/contact" do

	@name = params[:name]
	@email = params[:email]
	@message = params[:message]

	hh = {:name => "Введите ваше имя", :email => "Введите ваш email", :message => "Введите ваше сообщение"}

	hh.each do |key, value|
		if params[key] == ''
			@error = hh[key]
			return erb :contact
		end
	end

	Pony.mail({
		:to => 'scoundrel98@gmail.com',
		:subject => "#{params[:email]}",
		:body => "#{params[:name]} написал вам сообщение: #{params[:message]}",
		:via => :smtp,
		:via_options => {
		  :address              => 'smtp.gmail.com',
		  :port                 => '587',
		  :enable_starttls_auto => true,
		  :user_name            => 'scoundrel98@gmail.com',
		  :password             => '123456123aKaneo',
		  :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
		  :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
		}
	  }
	)

	db = get_db
	db.execute 'insert into Contacts (username, email, message) values (?,?,?)', [@name, @email, @message]
	
	f = File.open "./public/contacts.txt", "a"
	f.write "Имя: #{@name}, Email: #{@email}, Сообщение: #{@message}\n"
	f.close
	
	erb :contact
end

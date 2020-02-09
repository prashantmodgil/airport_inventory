module Database
	def Database.connect_db
		 Mysql2::Client.new(:host => "127.0.0.1", :username => "root",:password => "prashant")
	end
end
class Inventory
	require 'mysql2'
	require 'table_print'
	require 'yaml'
	include Database
	SEED = YAML::load_file("seedfile.yaml")
	@@client = Database.connect_db
	def self.seed
		@@client.query('DROP DATABASE IF EXISTS inventory')
		@@client.query('DROP TABLE IF EXISTS inventory.transaction')
		@@client.query('DROP TABLE IF EXISTS inventory.airport')
		@@client.query('CREATE DATABASE IF NOT EXISTS inventory')
		@@client.query('CREATE TABLE IF NOT EXISTS inventory.transaction(id INT auto_increment primary key,type VARCHAR(255),fuel FLOAT,aircraft VARCHAR(255),fuel_available FLOAT, trans_time TIMESTAMP, airport_name VARCHAR(255))')
		@@client.query('CREATE TABLE IF NOT EXISTS inventory.airport(id INT auto_increment primary key,name VARCHAR(255) UNIQUE,fuel_capacity FLOAT,fuel_available FLOAT, CHECK (fuel_available <= fuel_capacity))')
		SEED.each do |hash|
			@@client.query("INSERT INTO inventory.airport (name, fuel_capacity, fuel_available)VALUES ('#{hash["name"]}', #{hash["fuel_capacity"]}, #{hash["fuel_available"]})")
		end
	end

	def self.show_airports
		response = @@client.query('SELECT * FROM inventory.airport')
		tp response
	end

	def self.update_inventory port_id
		response = @@client.query("SELECT * FROM inventory.airport where id=#{port_id}")
		if response.none?
			puts "no record found"
		else
			puts "Enter Fuel (ltrs):"
			quantity = gets.chomp.to_i
			response.first["fuel_available"] += quantity
			if response.first["fuel_available"] <= response.first["fuel_capacity"]
				@@client.query("UPDATE inventory.airport SET fuel_available = #{response.first["fuel_available"]} where id=#{port_id}")
				@@client.query("INSERT INTO inventory.transaction (type,fuel,fuel_available,airport_name)VALUES('IN',#{quantity},#{response.first["fuel_available"]},'#{response.first["name"]}')")
				puts "Success: Fuel inventory updated"
			else
				puts "Error: Goes beyond fuel capacity of the airport"
			end
		end
	end

	def self.show_transactions
		response = @@client.query('SELECT * FROM inventory.transaction')
	 	tp response
	end

	def self.fill_aircraft port_id
		response = @@client.query("SELECT * FROM inventory.airport where id=#{port_id}")
		if response.none?
			puts "no record found"
		else
			puts "Enter Aircraft Code:"
			aircraft = gets
			puts "Enter Fuel (ltrs):"
			quantity = gets.chomp.to_i
			if response.first["fuel_available"] >= quantity
				response.first["fuel_available"] -= quantity
				@@client.query("UPDATE inventory.airport SET fuel_available = #{response.first["fuel_available"]} where id=#{port_id}")
				@@client.query("INSERT INTO inventory.transaction (type,fuel,fuel_available,airport_name,aircraft)VALUES('OUT',#{quantity},#{response.first["fuel_available"]},'#{response.first["name"]}','#{aircraft}')")
				puts "Success: Request for the has been fulfilled"
			else
				puts "Failure: Request for the fuel is beyond availability at airport"
			end
		end
	end


	loop do
		puts "Choose Your Option:"
			input = gets.chomp.to_i
			case input
			when 0
				Inventory.seed
			when 1
				Inventory.show_airports
			when 2
				puts "Enter Airport ID:"
				port_id = gets.chomp.to_i
				Inventory.update_inventory port_id
			when 3
				puts "Please Enter Airport id"
				port_id = gets.chomp.to_i
				Inventory.fill_aircraft port_id
			when 4
				Inventory.show_transactions
			when 9
				return
			else
				puts "wrong input"
			end
	end
end

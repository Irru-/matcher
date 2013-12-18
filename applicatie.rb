#!/usr/local/bin/ruby
# http://www.railstation.eu
# Peter Dierx - 2013

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'geocoder'
require 'sinatra'
require 'sinatra/reloader'
require 'nokogiri'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-constraints'

# RELOAD
also_reload "#{ settings.root }/applicatie.rb"

# CONFIGURE geocoder
Geocoder.configure(:units => :km)
include Geocoder::Calculations

class Vacature
  
  include DataMapper::Resource

  property :id,       Serial
  property :functie,  String
  property :uren,     Integer
  property :locatie,  String
	
	def self.match( p )
	
		if p[:locatie] == ''
      res = all(:locatie => p[:locatie], :uren => p[:uren], :functie => p[:functie])
    else
      res = all(:locatie => p[:locatie], :uren => p[:uren], :functie.like => ("%" + p[:functie] + "%"))  
    end
		
		if res.empty?
			res = all(:functie.like => ("%" + p[:functie] + "%"), :uren => p[:uren])
		else
		end
		
		res.delete_if{ |x| 
		
			d = distance_between(p[:locatie], x.locatie)
			d2 = d.round(1)
			
			d2 > p[:afstand].to_i
		
		}	
		
	end

end

class Location

	include DataMapper::Resource
	
	property :id,					Serial
	property :stad, 			String
	property :long,			Float
	property :lat,				Float
	
	def self.check( s )
	
		res = all(:stad => s)
		
		if res.empty?
			c = Geocoder.search(s)
			long 	= c[0].longitude
			lat 		= c[0].latitude
			
			Location.create(:stad => s, :long => long, :lat => lat)
			
			res = all(:stad => s)
			
		end
		
		res
	
	end

	def self.calc( s1, s2 )
	
		res1 = all(:stad => s1)
		res2 = all(:stad => s2)
		
	end

configure :development do

  DataMapper.setup( :default, "sqlite3://#{ Dir.pwd }/database.sqlite3")

end


DataMapper.auto_upgrade!


get '/' do
  erb :index
end

get '/string' do
  @html_doc = Nokogiri::HTML( '<html><body><h1>Mr. Belvedere Fan Club</h1></body></html>' )
  erb :string, :layout => false
end

get '/bestand' do
  bestand   = File.open( "#{ settings.root }/bestanden/demo.html" )
  @html_doc = Nokogiri::HTML( bestand )
  bestand.close
  erb :string, :layout => false
end

get '/acteur' do
  bestand  = File.open( "#{ settings.root }/bestanden/shows.xml" )
  xml_doc = Nokogiri::XML( bestand )
  @acteurs = xml_doc.xpath( '//character' )
  bestand.close
  erb :acteur
end

get '/serie' do
  xml_doc = Nokogiri::XML( File.open( "#{ settings.root }/bestanden/shows.xml" ) )
  @series = xml_doc.xpath( '//name')
  erb :serie
end

get '/drama' do
  # css selector
  xml_doc = Nokogiri::XML( File.open( "#{ settings.root }/bestanden/shows.xml" ) )
  @drama  = xml_doc.css( 'dramas name' ).first
  erb :drama
end

get '/functies' do
  html_doc   = Nokogiri::HTML( File.open( "#{ settings.root }/bestanden/starapple.html" ) )
  @functies = html_doc.xpath( '//functie' )
  erb :functie
end

get '/vacatures' do
  html_doc   = Nokogiri::HTML( File.open( "#{ settings.root }/bestanden/starapple.html" ) )
  @vacatures = html_doc.css( '#omschrijving' )

  @vacatures.each do |vacature|

    jobs = Vacature.new
    jobs.functie  = vacature.elements[0].content
    jobs.locatie  = vacature.elements[1].content
    jobs.uren     = vacature.elements[2].content
    jobs.save

  end

  if params['reeks']
    @reeks = params['reeks']
  else
    @reeks = ["Test"]
  end

  erb :vacature
end

get '/argumenten' do

  "#{params.inspect}"

end

get '/form' do
	@vacature = Vacature.new
	erb :form
end

post '/verwerk' do

  #vac = Vacature.new

  #vac.functie   = params[:functie]
  #vac.locatie   = params[:locatie]
  #vac.uren      = params[:uren]

  #vac.save

  #reeks = [vac.uren]

  redirect "/try?u=#{params[:uren]};c=0"

end

post '/locatie' do

  redirect "/try?u=#{params[:locatie]};c=1"

end

post '/functie' do

  redirect "/try?u=#{params[:functie]};c=2"

end

post '/match' do

  #redirect "/try?u=#{params[:locatie]};a=#{params[:uren]};b=#{params[:functie]};c=3;d=#{params[:afstand]}"
	
	#@vac = Vacature.new( params[:vacature] )
	#@vac = params
	#rofl = params
	#@vac
	
	#erb:trial
	
	#redirect 
	
	@p = params[:match]
	@res = Vacature.match(@p)
	erb :try

end

get '/trial' do

	@res = Location.check("Rotterdam")
	erb :trial

end


post '/try' do

	@p = params
	
	 if @p[:locatie] == ''
      @res = Vacature.all(:locatie => @p[:locatie], :uren => @p[:uren], :functie => @p[:functie])
    else
      @res = Vacature.all(:locatie => @p[:locatie], :uren => @p[:uren], :functie.like => ("%" + @p[:functie] + "%"))  
    end
	
  erb :try


end
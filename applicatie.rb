#!/usr/local/bin/ruby
# http://www.railstation.eu
# Peter Dierx - 2013

$LOAD_PATH.unshift File.dirname(__FILE__)

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

class Vacature
  
  include DataMapper::Resource

	property :id,										Serial
	property :url_id,								Integer
	property :title,								String
	property :bedrijf,							String
	property :dienstverband,	String
	property :plaats,							String
	property :omschrijving,		String
	property :version,						Integer
	
	has n,	:vacatures_educations, :through => Resource
	has n, 	:vacatures_locations, :through => Resource
	has n, 	:vacatures_skills, :through => Resource

	end

class VacaturesEducation

	include DataMapper::Resource
	
	storage_names[:default] = "vacatures_educations"
	
	property :id,									Serial
	property :vacature_id, 		Integer
	property :education_id, 	Integer
	
	has n,	:vacature, :through => Resource
	has n, 	:educations, :through => Resource
	
end
	
class Education

	include DataMapper::Resource
	
	property :id,									Serial
	property :education,			String
	property :level,							Integer
	
	has n, 	:vacatures_educations, :through => Resource
	
end
	
class VacaturesLocation

	include DataMapper::Resource
	
	storage_names[:default] = "vacatures_locations"

	property :id,									Serial
	property :vacature_id, 		Integer
	property :location_id,		 	Integer
	
	has n, :vacatures, :through => Resource
	
end

class Location

	include DataMapper::Resource
	
	property :id,									Serial
	property :name,						String
	property :longitude,				Float
	property :latitude,					Float
	
	has n,	:vacatures_locations, :through => Resource

end

class VacaturesSkill

	include DataMapper::Resource
	
	storage_names[:default] = "vacatures_skills"

	property :id,									Serial
	property :vacature_id, 		Integer
	property :skill_id,					 	Integer
	
	has n, :skills, :through => Resource
	
end

class Skill
	
	include DataMapper::Resource
	
	property :id,								Serial
	property :skill,						String

	has n, 	:vacatures_skills, :through => Resource
end

configure :development do

  #DataMapper.setup( :default, "sqlite3://#{ Dir.pwd }/database.sqlite3")
  DataMapper.setup( :default, 'mysql://jobhearted:RAM2675132@mysql.insidion.com/jobhearted')

end

DataMapper.finalize

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

  redirect "/try?u=#{params[:locatie]};a=#{params[:uren]};b=#{params[:functie]};c=3"

end


get '/try' do

	@q = Vacature.all
	
  erb :try

end
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

include Geocoder::Calculations

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
	
	has n, :vacatures_locations
	has n, :locations, :through => :vacatures_locations
	
	has n, :vacatures_educations
	has n, :educations, :through => :vacatures_educations
	
	has n, :vacatures_skills
	has n, :skills, :through => :vacatures_skills
end

class VacaturesEducation

	include DataMapper::Resource
	
	storage_names[:default] = "vacatures_educations"
	
	property :id,									Serial
	property :vacature_id, 		Integer
	property :education_id, 	Integer
	
	belongs_to :vacature
	belongs_to :education
	
end
	
class Education

	include DataMapper::Resource
	
	property :id,					Serial
	property :education,			String
	property :level,				Integer
	
	has n, :vacatures_educations
	has n, :vacatures, :through => :vacatures_educations	
	
end
	
class VacaturesLocation

	include DataMapper::Resource
	
	storage_names[:default] = "vacatures_locations"

	property :id,				Serial
	property :vacature_id, 		Integer
	property :location_id,		Integer
	
	belongs_to :vacature
	belongs_to :location
	
end

class Location

	include DataMapper::Resource
	
	property :id,						Serial
	property :name,						String
	property :longitude,				Float
	property :latitude,					Float

	def self.calc(s1,s2)

		res1		= self.check(s1)
		res2		= self.check(s2)	

		
        lat1        = res1.latitude
        lon1        = res1.longitude
        
        lat2        = res2.latitude
        lon2        = res2.longitude
               
        r           = 6371
        dLat        = (lat2 - lat1) * Math::PI / 180
        dLon        = (lon2 - lon1) * Math::PI / 180
        lat1        = res1[:latitude] * Math::PI / 180
        lat2        = res2[:latitude] * Math::PI / 180
                
        a           = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
        c           = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
        d           = r * c
	end

	def self.check(s1)

		res = first(:name => s1)

		if res.nil?

			c 		= Geocoder.search(s1)
			long 	= c[0].longitude
			lat 	= c[0].latitude
			Location.create(:name => s1, :longitude => long, :latitude => lat) 

		end

		res = first(:name => s1)

	end

	def self.grade(s1, s2, i)

		res 	= 0
		d 		= self.calc(s1,s2)
		d 		= d.to_i
		step 	= i*0.1
		dif 	= d - i
		dif2	= (dif / step) * 5

		if d < i
			res = 100
		else
			res = 100 - dif2
			if res < 0
				res = 0
			end
		end


		res


	end

	has n, :vacatures_locations
	has n, :vacatures, :through => :vacatures_locations
	
end

class VacaturesSkill

	include DataMapper::Resource
	
	storage_names[:default] = "vacatures_skills"

	property :id,				Serial
	property :vacature_id, 		Integer
	property :skill_id,			Integer	
	
	belongs_to :vacature
	belongs_to :skill
	
end

	
class Skill
	include DataMapper::Resource
	
	property :id,					Serial
	property :skill,				String

	def self.calc(s1)

		s1 = "%" + s1 + "%"

		res = all(:skill.like => s1)

	end
	
	has n, :vacatures_skills
	has n, :vacatures, :through => :vacatures_skills
	
end

configure :development do

  #DataMapper.setup( :default, "sqlite3://#{ Dir.pwd }/database.sqlite3")
  DataMapper.setup( :default, 'mysql://jobhearted:RAM2675132@mysql.insidion.com/jobhearted2')

end

DataMapper.finalize

DataMapper.auto_upgrade!


get '/' do
  erb :index
end

get '/try' do

	@s1 = "Rotterdam"
	@s2 = "Eindhoven"
	@s3 = "C#"
	@i 	= 40

	@res 	= Location.grade(@s1, @s2, @i)
	@res2 	= Location.calc(@s1, @s2)
	@res3 	= Skill.calc(@s3) 


	test = VacaturesEducation.all(:vacature => 
	[
		{
			:bedrijf => "Adecco"
		}
	]
	)
	
	a = VacaturesEducation.all(:education_id => 2)
	@z = a.all(:vacature =>
	[	
		{
			:vacatures_locations =>
				[
					{
						:location_id => 27
					}
				]	
		}
	]
)	

  erb :try

end
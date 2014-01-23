#!/usr/local/bin/ruby
# http://www.railstation.eu
# Peter Dierx - 2013

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'benchmark'
require 'geocoder'
require 'haml'
require 'sinatra'
require 'sinatra/reloader'
require 'nokogiri'
require 'dm-aggregates'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-constraints'
require 'pdf/reader'

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

class Url

	include DataMapper::Resource
	
	storage_names[:default] = "urls"
	
	property :id,										Serial
	property :url,									String
	
	#URL opzoeken die bij de vacature hoort.
	def self.getLink(vacatureHash)
	
		result = Array.new
		
		vacatureHash.each do |k,v|
		
			temp = first(:id => k.url_id)
			result << temp.url
		
		end
		
		result
	
	end
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
	
	property :id,									Serial
	property :education,			String
	property :level,							Integer

	def self.calc(vacArray, edu)
	
		res = Array.new

		vacArray.each do |vac|
		#Loop door elke vacature heen van de array
		
			vEduCol = VacaturesEducation.all(:vacature_id => vac.id)
			#Zoek vervolgens alle educations die horen bij de vacature
			size = vEduCol.count
			#Tel hoeveel resultaten er zijn
			
			if size != 0
			
				if size == 1
				#Als er maar 1 hit is, voeg dan het level toe aan het result
					vEduCol.each do |vEdu|
						
						lvl = vEdu.education.level
						
						res << lvl
						
					end
					
				else
				#Zijn er meerdere, voeg dan een array aan result toe
					mScore = Array.new
					
					vEduCol.each do |vEdu|
						
						lvl = vEdu.education.level
						mScore << lvl
						
					end
					
					res << mScore
					
				end
			
			else
				res << 0
			end			

		end		

		grade(res, edu)

	end
	
	def self.grade(eduLevelArray, edu)
		
		res = Array.new
		
		eduLevelArray.each do |level|

			if !level.kind_of?(Array)
		
				res << getGrade(level, edu)

			else
			#Als level een array is, voeg dan de hoogste waarde toe aan result.
				temp = Array.new

				level.each do |lvl|

					temp << getGrade(lvl, edu)

				end

				res << temp.max

			end
				
		end
		
		res
		
	end

	def self.getGrade(level, edu)

		if edu >= level
			return 100
		end	
		
		if level != 0
			
			return (edu * 100 / level)
		
		else
			
			return 80			
			
		end

	end
	
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

class Distance

	include DataMapper::Resource
	
	property	:id,					Serial
	property	:stad1,			String
	property	:stad2,			String
	property	:distance,	Float
	
	def self.getDistance(locatie1, locatie2)
	
		result = first(:stad1 => locatie1, :stad2 => locatie2)
			
		if result.nil?
			
			afstand = Location.calc(locatie1, locatie2)
			create(:stad1 => locatie1, :stad2 => locatie2, :distance => afstand)
			result = afstand
			
		else
			result = result.distance
		end
		
		result
	
	end
	

end

class Location

	include DataMapper::Resource
	
	storage_names[:default] = "locations"
	
	property :id,									Serial
	property :name,						String
	property :longitude,				Float
	property :latitude,					Float

	def self.calc(locatie1,locatie2)	

		
	res1 = first(:name => locatie1)
	res2 = first(:name => locatie2)
				
	lat1 = res1.latitude
	lon1 = res1.longitude
        
    if !res2.nil?
		lat2        = res2.latitude
        lon2        = res2.longitude
	else
		lat2		= 36
		lon2		= 138
	end
               
    r           = 6371
    dLat        = (lat2 - lat1) * Math::PI / 180
    dLon        = (lon2 - lon1) * Math::PI / 180
    lat1        = lat1 * Math::PI / 180
    lat2        = lat2 * Math::PI / 180
              
    a           = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
    c           = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    d           = r * c
				
	end

	def self.grade(locatie1, locatie2, distance)

		res 	= 0
		d 		= Distance.getDistance(locatie1,locatie2)
		if d == 0.0
			return 100
		end
		d 		= d.to_i
		step 	= distance*0.1
		dif 	= d - distance
		dif2	= (dif / step) * 5

		if d < distance
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
	
	storage_names[:default] = "skills"
	
	property :id,					Serial
	property :skill,				String
	
	has n, :vacatures_skills
	has n, :vacatures, :through => :vacatures_skills

	def self.getID(array)

		result = Array.new

		array.each do |item|

			temp = first(:skill => item)
			if !temp.nil?
				result << temp.id
			end

		end

			query = "SELECT vacature_id, COUNT(skill_id) as count FROM vacatures_skills WHERE "

			result.each do |number|

				query = query + "skill_id=" + number.to_s + " OR "

		end

		query = query[0..-5] + " GROUP BY vacature_id ORDER BY count DESC LIMIT 100"

		res = repository(:default).adapter.select(query)

	end
	
	def self.getCount(array, total)
	
		result = Array.new
		
		array.each do |item|
			
			result << ((item.count * 100) / total )
		
		end

		result
	
	end
end

class Match

	def self.getVac(sk, dvb)
	
		skill = "%" + sk + "%"
		dienst = "%" + dvb + "%"
		
		result = Array.new
	
		res = VacaturesSkill.all(
		:skill =>
		[{:skill.like => skill}],
		:vacature =>
		[{:dienstverband.like => dienst}]
		)
		
		res.each do |vacskill|
		
			result << vacskill.vacature
		
		end
		
		result
	
	end
	
	def self.getVacatures(array, dvb)
	
		result = Array.new
		
		array.each do |item|
		
			temp = Vacature.first(:id => item.vacature_id, :dienstverband.like => dvb)
			if !temp.nil?
				result << temp
			end
			
		end
		
		result
	
	end
	
	def self.matchLoc(vacatures,locatie,distance)
	
	result = Array.new

		vacatures.each do |vacature|				
			
			plaats = vacature.plaats.downcase
			locatie = locatie.downcase
			result << Location.grade(locatie,plaats,distance)
			
		end
		
	result
	
	end

	def self.scoreCV(vacatures,locationScore,lw,eduScore,ew,skillScore,sw)
	
		result = Hash.new
		scoreArray = Array.new
		total = lw+ew+sw
		
		
		vacatures.each_with_index do |vac, i|
		
			lScore = locationScore[i] * lw
			eScore = eduScore[i]*ew
			sScore = skillScore[i]*sw
			
			score = ((lScore + eScore + sScore)/total)
			scoreArray = [locationScore[i], eduScore[i], skillScore[i], score]
			
			result.merge!(vac => scoreArray)
		
		end
		
		result
	
	end
	
	def self.scoreForm(vacatures,locationScore,lw,eduScore,ew)
	
		result = Hash.new
		scoreArray = Array.new
		total = lw+ew
		
		
		vacatures.each_with_index do |vac, i|
		
			lScore = locationScore[i] * lw
			eScore = eduScore[i]*ew
			
			score = ((lScore + eScore)/total)
			scoreArray = [lScore/total, eScore/total, score]
			
			result.merge!(vac => scoreArray)
		
		end
		
		result
	
	end
end

class CV

	def self.getText(filename)
		
		text = ""
	
		PDF::Reader.open(filename) do |reader|
			reader.pages.each do |page|
				text = text + page.text.downcase
			end
		end
		
		text
	
	end
	
	def self.getCity(text)
	
		plaatsen = Location.all()
		result = Array.new
		text = text.downcase
		textArray = text.split(' ')
		result = nil
		
		textArray.each do |word|
		
			plaatsen.each do |plaats|
			
				if !plaats.name.empty?
				
					word = word.downcase
					plaats = plaats.name.downcase
					
					if word.eql? plaats					
						return word					
					end
					
				end
				
			end		
		
		end		

	end
	
	def self.getSkills(text)
	
		skills = Skill.all()
		result = Array.new
		
		skills.each do |skill|
	
			naam = nil
			if !skill.skill.empty?
				naam = skill.skill.downcase				
				res = text.scan(/\b#{naam}\b/)			
			end
			
			if !res.nil?
				if !res.empty?
					result << res[0]
				end
			end
		end
		
		result
		
	end

	def self.getEducation(text)
		
		edus = Education.all()
		result = Array.new
		
		edus.each do |edu|
		
			naam = nil
			if !edu.education.empty?
				naam = edu.education.downcase
				res = text.scan(/\b#{naam}\b/)
			end
			
			if !res.nil?
				if !res.empty?
					result << res[0]
				end
			end		
		end
		
		result
	
	end
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

post '/match' do
	
	@p = params[:match]
	l1 = @p["l1"]
	l2 = @p["l2"]
	sk = @p["sk"]
	di = @p["di"].to_i
	edu = @p["edu"].to_i
	dvb = @p["dvb"]
	dvb = "%" + dvb + "%"


	vacatures = Match.getVac(sk, dvb)

	locationScore = Match.matchLoc(vacatures, l1, di)

	@link = Url.getLink(vacatures)

	eduScore = Education.calc(vacatures, edu)

	score = Match.score(vacatures, locationScore, eduScore)
	@score = score.sort_by{|k,v| v}.reverse	

	erb :debug

end

get '/form' do
  erb :form
end

get '/pdf' do

	filename = File.expand_path(File.dirname(__FILE__)) + '/test3.pdf'
	
	
	@plaatsen = Location.all()
	@skills = Skill.all()
	
	@b = ""

	PDF::Reader.open(filename) do |reader|
		reader.pages.each do |page|
			@b = @b + page.text.downcase
		end
	end
	
	ps = "photoshop"
	
	@b = @b.scan(/\b#{ps}\b/)
	
	erb :pdf
end

# Handle GET-request (Show the upload form)
get "/upload" do

	erb :up
end      
    
# Handle POST-request (Receive and save the uploaded file)
post "/upload" do 

  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
    f.write(params['myfile'][:tempfile].read)
  end
  
	filename = File.expand_path(File.dirname(__FILE__)) + '/uploads/' + params['myfile'][:filename]
	
	text = CV.getText(filename)
	
	p = params[:match]
	distance = p["di"].to_i
	dvb = p["dvb"]
	dvb = "%" + dvb + "%"
	lw = p["lo"].to_i
	sw = p["sk"].to_i
	ew = p["ed"].to_i
	
	@plaats = CV.getCity(text)
	plaats = @plaats
	@tplaats = plaats
	
	@skills = CV.getSkills(text)
	@count = @skills.count	
	@skills = Skill.getID(@skills)	
	
	@edu = CV.getEducation(text)
	edu = Education.first(:education => @edu[0])
	edu = edu.level
	
	vacatures = Match.getVacatures(@skills, dvb)
	@vacatures = vacatures

	locationScore = Match.matchLoc(vacatures, plaats, distance)
	@ls = locationScore

	eduScore = Education.calc(vacatures, edu)
	@es = eduScore
	
	@skillScore = Skill.getCount(@skills, @count)
	
	score = Match.scoreCV(vacatures, locationScore, lw, eduScore, ew, @skillScore, sw) 
	@score = score.sort_by{|k,v| v[3]}.reverse	
	
	@link = Url.getLink(@score)	
	
	erb :matcher_cv
end

post "/uploadform" do

	@p = params[:match]
	
	l1 = @p["l1"]
	
	sk = @p["sk"]
	sks = @p["sks"]
	
	di = @p["di"].to_i
	lo = @p["lo"].to_i
	
	edu = @p["edu"].to_i
	ed = @p["ed"].to_i
	
	dvb = @p["dvb"]
	dvb = "%" + dvb + "%"


	vacatures = Match.getVac(sk, dvb)

	locationScore = Match.matchLoc(vacatures, l1, di)

	eduScore = Education.calc(vacatures, edu)

	score = Match.scoreForm(vacatures, locationScore, lo, eduScore, ed)
	@score = score.sort_by{|k,v| v[2]}.reverse	
	
	@link = Url.getLink(vacatures)

	erb :matcher_form

end
#! /usr/bin/env ruby

require 'rubygems'
require 'basecamp'
require 'clamp'

class BasecampExport < Clamp::Command

  option "--apikey", "APIKEY", "Your Basecamp API Key", :attribute_name => :apikey
  option "--basecampurl", "BASECAMPURL", "Your Basecamp URL (ie. myname.basecamphq.com)", :attribute_name => :basecampurl
  option "--project", "PROJECT", "The ID of your project", :attribute_name => :projectid

  self.default_subcommand = "projects"

  subcommand "projects", "get all projects" do
    def execute
    	checktoken
    	connect
    	puts "receiving all projects..."
		projects = Basecamp::Project.find(:all)
		puts "These are your projects:"
		projects.each_with_index do |p, index|
		puts "#{p.id} - #{p.name}"
		end
    end
  end

  subcommand "tasks", "get all tasks" do
    def execute
    	checktoken
    	checkproject
    	connect
		project = Basecamp::Project.find(projectid)
		puts "receiving all TODO lists for project '#{project.name}'..."
		todo_lists = Basecamp::TodoList.all(projectid)
		puts "received #{todo_lists.count} TODO lists."
		puts "\n"
		todo_lists.each do |list|
			puts list.name
			list.todo_items.each do |i|
				puts " #{(i.completed? ? "x" : "-")} #{i.content}"
			end
		end
    end
  end

  def checktoken
  	unless apikey && apikey.any?
  		puts "please provide your basecamp API key."
  	end

  	unless basecampurl && basecampurl.any?
  		puts "please provide your basecamp url."
  	end
  	exit(0) unless apikey.any? && basecampurl.any?
  end

  def checkproject
  	unless projectid && projectid.any?
  		puts "please provide your projectid."
  	end
  end

  def connect
	#connect to basecamp api using ssl
	puts "connecting to your basecamp account on '#{basecampurl}' with token '#{apikey}'"
	Basecamp.establish_connection!(basecampurl, apikey, 'X', true)
	@me = Basecamp::Person.me
	puts "Hello #{@me.user_name}"
  end

end

BasecampExport.run

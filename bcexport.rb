#! /usr/bin/env ruby

require 'rubygems'
require 'basecamp'
require 'clamp'
require 'spreadsheet'

class BasecampExport < Clamp::Command

  option "--apikey", "APIKEY", "Your Basecamp API Key", :attribute_name => :apikey
  option "--basecampurl", "BASECAMPURL", "Your Basecamp URL (ie. myname.basecamphq.com)", :attribute_name => :basecampurl
  option "--project", "PROJECT", "The ID of your project", :attribute_name => :projectid
  option "--excel", :flag, "Export data to Excel Worksheet"

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
  		if excel?
  			puts "exporting to excel worksheet..."
  			export_todo_lists_to_excel project, todo_lists
  		else
  			todo_lists.each do |list|
  				puts list.name
  				list.todo_items.each do |i|
  					puts " #{(i.completed? ? "x" : "-")} #{i.content}"
  				end
  			end
  		end
    end
  end

  def export_todo_lists_to_excel project, todo_lists
  	Spreadsheet.client_encoding = 'UTF-8'
  	book = Spreadsheet::Workbook.new
  	sheet = book.create_worksheet :name => "TODO Liste #{project.name}"

  	default_format = Spreadsheet::Format.new :color => :black,
                                   :weight => :normal,
                                   :size => 12
  	header_format = Spreadsheet::Format.new :color => :black,
                                   :weight => :bold,
                                   :size => 14
  	completed_format = Spreadsheet::Format.new :color => :green,
                                   :weight => :bold,
                                   :size => 12

    sheet.default_format = default_format
    sheet.row(0).default_format = header_format
    sheet.update_row 0, "Prio in Kategorie", "TODO Item", "Kategorie", "eingetragen am", "fällig am", "Verantwortlich", "fertiggestellt", "fertig am", "fertiggestellt von"

    index = 1
  	todo_lists.each do |list|
  		puts "\n"
  		puts "exporting list #{list.name}"
  		list.todo_items.each do |item|
  			#puts item.inspect
  			completer = nil
  			if item.completed
  				sheet.row(index).default_format = completed_format
  				print "*"
  			else
  				print "."
  			end
  			sheet.update_row index, item.position, item.content, list.name, item.created_on, item.due_at, (item.responsible_party_name rescue ""), item.completed, (item.completed_at rescue ""), (item.completer_name rescue "")
  			index += 1
  		end
  	end

  	book.write "todo_list.xls"
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

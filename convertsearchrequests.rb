#!/usr/bin/env ruby1.8
#
# Hacky script to go through searchrequest XML stored in a JIRA PostgreSQL database, replacing references to old IDs
# with their local equivalent.
#
# Relies on the newid() function from copy.plpgsql being defined in the database to look up new IDs from old.
#
# Note that when an entity (eg. a version or issue type) is deleted from JIRA, JIRA does not delete the now-invalid
# references in the searchrequest XML. Therefore this script will likely die on its first run. Customize
# known_invalid_idrefs to exclude bad IDs as you encounter them.

require 'rubygems'
require 'dbi'
require 'nokogiri'

# String in an XML comment identifying searchrequests that need converting.
# Inserted by copy.plpgsql's copysearchrequest function - if you customize this, modify that too.
MARKERSTR='CONVERTME: struts.searchrequest'

errmsg = "Please define PGDATABASE, PGUSER, PGPASSWORD and optionally PGHOST / PGPORT"
$db=ENV["PGDATABASE"] or raise errmsg
$dbuser=ENV["PGUSER"] or raise errmsg
$dbpassword=ENV["PGPASSWORD"] or raise errmsg
$dbh=DBI.connect("dbi:Pg:host=#{$dbhost};dbname=#{$db}", $dbuser, $dbpassword, nil)

# Some saved searches refer to things that have since been deleted. This function should return true if the referenced ID is known to be invalid.
def known_invalid_idref(mapkey, oldid)
	return false;
	# 	return ( ((mapkey==:version or mapkey==:fixfor) and oldid==21907 or oldid==21881 or oldid==21743) or
	# 			(mapkey==:version and (oldid==21240 or oldid==21743)) or 
	# 			(mapkey==:issuestatus and (oldid==2 or oldid==-3)) or
	# 			(mapkey==:resolution and oldid==6)
	# 	   )
end

def translateid(mapkey, oldid)
	newid=$dbh.select_one("select newid('#{mapkey}', ?)", oldid)[0]
	if (!newid) then
		return nil;
	end 
        return newid.to_s.to_i
end 

# Fish searchrequest records created by a valid (imported) user out of the old JIRA
rows = $dbh.select_all("select * from public.searchrequest where reqcontent like '%<!-- #{MARKERSTR} %'")
rows.each do |row|

	# Manipulate the searchrequest XML, rewriting IDs according to the $JiraIDMap mapping
	sr = Nokogiri::XML(row["reqcontent"])
	commentnode = sr.xpath "comment()[contains(., '#{MARKERSTR} ')]"
	oldsrid = commentnode.to_s.scan(/#{MARKERSTR} (\d+)/)[0][0].to_i
	commentnode.remove

	# Sample searchrequest XML:
	# 
	# <searchrequest name='Issues reported by current user'>
	#   <parameter class='com.atlassian.jira.issue.search.parameters.lucene.ProjectParameter'>
	#     <projid andQuery='false'>
	#       <value>10130</value>
	#     </projid>
	#   </parameter>
	#   <parameter class='com.atlassian.jira.issue.search.parameters.lucene.UserParameter'>
	#     <issue_author name='issue_author' value='issue_current_user'/>
	#   </parameter>
	#   <sort class='com.atlassian.jira.issue.search.SearchSort'>
	#     <searchSort field='issuekey' order='DESC'/>
	#   </sort>
	# </searchrequest>

	sr.root.add_previous_sibling(Nokogiri::XML::Comment.new(sr, "SearchRequest converted from id #{oldsrid} in old database"))
	# Possible elements: projid status version priority issue_author issue_assignee component   fixfor resolution type created
	# Elements we care about: projid version fixfor status priority component resolution type 
	srElements = {"projid"=>:project,
	"version"=>:projectversion,
	"fixfor"=>:projectversion,
	"status"=>:issuestatus,
	"resolution"=>:resolution,
	"priority"=>:priority,
	"component"=>:component,
	"type"=>:issuetype}

	srElements.each do |fieldname, mapkey|
		sr.search("#{fieldname}/value/text()").each { |v|
			oldid=v.to_s.to_i
			newid = translateid(mapkey, oldid)
			if (!newid) then
				if known_invalid_idref(mapkey, oldid) then	
					next
				else
					$stderr.puts "SearchRequest #{oldsrid} refers to nonexistent #{mapkey} id #{oldid}. If this ID legitimately doesn't exist (eg. that #{mapkey} was deleted) then add the bad ID to the known_invalid_idref function in this script."
					$stderr.puts sr
					exit(1)
					# To keep going despite errors, instead use:
					# next
				end
			else
				comment=Nokogiri::XML::Comment.new(sr, "#{oldid} in old JIRA")
				v.parent.add_previous_sibling(comment)
				v.content=newid
			end
		}
	end
	# PeriodParameter has been removed, but we still seem to have some. Do what UpgradeTask_Build26.java does, converting:
	# <parameter class="com.atlassian.jira.issue.search.parameters.lucene.PeriodParameter"><updated name="updated:previous" value="3600000" operator="&gt;="/></parameter>
	# to:
	# <parameter class="com.atlassian.jira.issue.search.parameters.lucene.RelativeDateRangeParameter"><updated name='updated:relative'><previousOffset>604800000</previousOffset></updated></parameter>
	sr.xpath("//parameter[@class='com.atlassian.jira.issue.search.parameters.lucene.PeriodParameter']").each { |param|
		puts "Fixing obsolete PeriodParameter on new searchrequest"
		builder=Nokogiri::XML::Builder.with(param.parent) { |xml|
			xml.parameter(:class=>"com.atlassian.jira.issue.search.parameters.lucene.RelativeDateRangeParameter") {
				if (param.search("updated").size > 0) then
					xml.updated(:name=>"updated:relative") {
						xml.previousOffset(param.xpath("updated/@value")) 
					}
				elsif (param.search("created").size > 0) then
					xml.created(:name=>"created:relative") {
						xml.previousOffset(param.xpath("created/@value")) 
					}
				end
			}
		}
		param.remove
	}

	newsearchrequest=sr.to_s
	puts "Row #{row["id"]}: converting «#{row["reqcontent"]}» TO «#{newsearchrequest}»";
	$dbh.execute("update searchrequest set reqcontent=? where id=?", newsearchrequest, row["id"])
end
puts "#{rows.size} rows found and converted."

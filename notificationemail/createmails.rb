#!/usr/bin/env ruby
#
# Generate a recipients/ directory containing users we should notify of their username change. A subdirectory is created
# for each user, containing separate files for the recipient name, email address and email body. sendmail.sh then does
# the actual sending.

require 'fileutils'
require 'uri'

$db=ENV["PGDATABASE"] or raise "Please define PGDATABASE and friends so 'psql' connects to the JIRA rename database."

Recips={}

`psql -F "	" -tAc "set search_path=struts; select oldusername, u.username, u.email, u.fullname, assignees+reporters+comments+changes as activity  from renameusers r, public.userdetails u, public.userusages uu where r.newusername=u.username and not exists (select * from struts.userbase where username=r.oldusername) and u.username=uu.username;"`.each do |l|
	email=l.split("\t")[2]
	r={}
	r[:oldusername], r[:newusername], r[:email], r[:fullname], r[:activity] = l.chomp.split("\t")
	r[:activity] = r[:activity].to_i
	if (Recips[email]) then
		Recips[email] << r
	else
		Recips[email] = [r]
	end
end

Recips.each do |k,v|
	subject="Re: issues.apache.org/struts user account renamed to '#{v[0][:newusername]}'"
	to="\"#{v[0][:fullname]}\" <#{v[0][:email]}>"
	body=%{
 Hi,

You are receiving this email because you have #{v.size==1?"a user account":"user accounts"} on the Apache Struts JIRA, https://issues.apache.org/struts

The Apache Infrastructure team has merged the Struts JIRA content into the main JIRA, https://issues.apache.org/jira/. During this process we have consolidated accounts to avoid duplicates. Content owned by your #{v.collect{|vv|"'"+vv[:oldusername]+"'"}.join " and "} account#{v.size==1?"":"s"} on the old Struts JIRA is now owned by '#{v[0][:newusername]}' on https://issues.apache.org/jira/:

https://issues.apache.org/jira/secure/Dashboard.jspa?os_username=#{URI.escape(v[0][:newusername])}

If you have forgotten your password, it can be reset at:

https://issues.apache.org/struts/secure/ForgotPassword!default.jspa?username=#{URI.escape(v[0][:newusername])}

#{v.inject(0){|o,n|o+n[:activity]}>5 ? "If you desperately prefer your old #{v.collect{|vv|"'"+vv[:oldusername]+"'"}.join " or "} username to '#{v[0][:newusername]}', please let us know and we can rename your user.":"Please let us know if you have any questions."}



Regards,

Jeff
Apache Infrastructure Team}
	recipdir=File.join "recipients", k
	FileUtils.mkdir_p recipdir
	File.open File.join(recipdir, "subject"), "w" do |subjectfile| subjectfile << subject; end
	File.open File.join(recipdir, "to"), "w" do |tofile| tofile << to; end
	File.open File.join(recipdir, "body"), "w" do |bodyfile| bodyfile << body; end
end
puts "Processed #{Recips.size} users"

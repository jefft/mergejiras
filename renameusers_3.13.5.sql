-- PostgreSQL (PL/pgSQL) function that renames usernames in a JIRA 3.13.5 database.
-- 
-- The function assumes the existence of a 'renameusers' table, containing a list of usernames to rename. Eg. to rename 'john.smith' to 'jsmith':
-- 
--   jira_strutsmerge_3135=> \i renameusers.sql
--   jira_strutsmerge_3135=> CREATE TABLE renameusers (oldusername VARCHAR, newusername VARCHAR);
--   CREATE TABLE
--   jira_strutsmerge_3135=> INSERT INTO renameusers VALUES ('john.smith', 'jsmith');
--   INSERT 0 1
--   jira_strutsmerge_3135=> SELECT renameusers();
-- 
-- The renameusers function is idempotent.
-- 
-- Based on prior work by Srini Ramaswamy, Peter Wik and others on JRA-1549:
-- http://jira.atlassian.com/browse/JRA-1549?page=com.atlassian.jira.plugin.system.issuetabpanels:all-tabpanel&focusedCommentId=181507&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#action_181507
-- 
-- Jeff Turner <jefft@apache.org>, 2010-02-19

create or replace function renameusers() returns void as $$
DECLARE
	rec RECORD;
BEGIN
	update changegroup a set AUTHOR = (select b.newusername from renameusers b where b.oldusername = a.AUTHOR)
	where a.AUTHOR in (select c.oldusername from renameusers c);

	update columnlayout a set username = (select b.newusername from renameusers b where b.oldusername = a.username)
	where a.username in (select c.oldusername from renameusers c);

	update component a set lead = (select b.newusername from renameusers b where b.oldusername = a.lead)
	where a.lead in (select c.oldusername from renameusers c);

	update FAVOURITEASSOCIATIONS a set USERNAME = (select b.newusername from renameusers b where b.oldusername = a.USERNAME)
	where a.USERNAME in (select c.oldusername from renameusers c);

	update fileattachment a set author = (select b.newusername from renameusers b where b.oldusername = a.author)
	where a.author in (select c.oldusername from renameusers c);

	update filtersubscription a set username = (select b.newusername from renameusers b where b.oldusername = a.USERNAME)
	where a.USERNAME in (select c.oldusername from renameusers c);

	update jiraaction a set author = (select b.newusername from renameusers b where b.oldusername = a.author)
	where a.author in (select c.oldusername from renameusers c);

	update jiraaction a set updateauthor = (select b.newusername from renameusers b where b.oldusername = a.updateauthor)
	where a.updateauthor in (select c.oldusername from renameusers c);

	update jiraissue a set reporter = (select b.newusername from renameusers b where b.oldusername = a.reporter)
	where a.reporter in (select c.oldusername from renameusers c);

	update jiraissue a set assignee = (select b.newusername from renameusers b where b.oldusername = a.assignee)
	where a.assignee in (select c.oldusername from renameusers c);

	update jiraworkflows a set creatorname=(select b.newusername from renameusers b where b.oldusername = a.creatorname)
	where a.creatorname in (select c.oldusername from renameusers c);

	update mailserver a set mailusername = (select b.newusername from renameusers b where b.oldusername = a.MAILUSERNAME)
	where a.mailusername in (select c.oldusername from renameusers c);

	update membershipbase a set user_name = (select b.newusername from renameusers b where b.oldusername = a.user_name)
	where a.user_name in (select c.oldusername from renameusers c);

	update os_currentstep a set owner = (select b.newusername from renameusers b where b.oldusername = a.owner)
	where a.owner in (select c.oldusername from renameusers c);

	update os_currentstep a set caller = (select b.newusername from renameusers b where b.oldusername = a.caller)
	where a.caller in (select c.oldusername from renameusers c);

	update os_historystep a set owner = (select b.newusername from renameusers b where b.oldusername = a.owner)
	where a.owner in (select c.oldusername from renameusers c);

	update os_historystep a set caller = (select b.newusername from renameusers b where b.oldusername = a.caller)
	where a.caller in (select c.oldusername from renameusers c);

	update portalpage a set username = (select b.newusername from renameusers b where b.oldusername = a.username)
	where a.username in (select c.oldusername from renameusers c);

	update project a set lead = (select b.newusername from renameusers b where b.oldusername = a.lead)
	where a.lead in (select c.oldusername from renameusers c);

	update PROJECTROLEACTOR a set ROLETYPEPARAMETER = (select b.newusername from renameusers b where b.oldusername = a.ROLETYPEPARAMETER)
	where a.ROLETYPEPARAMETER in (select c.oldusername from renameusers c);

	update SCHEMEPERMISSIONS a set PERM_PARAMETER = (select b.newusername from renameusers b where b.oldusername = a.PERM_PARAMETER)
	where a.PERM_PARAMETER in (select c.oldusername from renameusers c);

	update searchrequest a set authorname = (select b.newusername from renameusers b where b.oldusername = a.authorname)
	where a.authorname in (select c.oldusername from renameusers c);

	update searchrequest a set username = (select b.newusername from renameusers b where b.oldusername = a.username)
	where a.username in (select c.oldusername from renameusers c);

	update userassociation a set source_name = (select b.newusername from renameusers b where b.oldusername = a.source_name) where a.source_name in (select c.oldusername from renameusers c);

	-- At one stage the above userassociation update was failing, and I had to replace it with this snippet to see which username was duplicated:
-- 	for rec in select * from renameusers LOOP
-- 		RAISE NOTICE 'Renaming % to %', rec.oldusername,rec.newusername;
-- 		BEGIN
-- 			update userassociation a set source_name = rec.newusername where source_name=rec.oldusername;
-- 		EXCEPTION WHEN unique_violation THEN
-- 			RAISE NOTICE 'Caught error; continuing';
-- 		end;
-- 	end loop;
-- 
	update userbase a set username = (select b.newusername from renameusers b where b.oldusername = a.username) where a.username in (select c.oldusername from renameusers c);

	update WORKLOG a set AUTHOR = (select b.newusername from renameusers b where b.oldusername = a.AUTHOR)
	where a.AUTHOR in (select c.oldusername from renameusers c);

	update WORKLOG a set UPDATEAUTHOR = (select b.newusername from renameusers b where b.oldusername = a.UPDATEAUTHOR)
	where a.UPDATEAUTHOR in (select c.oldusername from renameusers c);

	-- FIXME: We should restrict replacements to custom field types that are known to store usernames.
	update CUSTOMFIELDVALUE a set STRINGVALUE=(select b.newusername from renameusers b where b.oldusername = a.STRINGVALUE)
	where a.STRINGVALUE in (select c.oldusername from renameusers c);
	update changeitem set OLDVALUE = (select newusername from renameusers where oldusername = OLDVALUE) where OLDVALUE in (select oldusername from renameusers) and field~*'assignee';
	update changeitem set NEWVALUE = (select newusername from renameusers where oldusername = NEWVALUE) where NEWVALUE in (select oldusername from renameusers) and field~*'assignee';
	update changeitem set OLDSTRING = (select newusername from renameusers where oldusername = OLDSTRING) where OLDSTRING in (select oldusername from renameusers) and field~*'assignee';
	update changeitem set NEWSTRING = (select newusername from renameusers where oldusername = NEWSTRING) where NEWSTRING in (select oldusername from renameusers) and field~*'assignee';
	update changeitem set OLDVALUE = (select newusername from renameusers where oldusername = OLDVALUE) where OLDVALUE in (select oldusername from renameusers) and field~*'reporter';
	update changeitem set NEWVALUE = (select newusername from renameusers where oldusername = NEWVALUE) where NEWVALUE in (select oldusername from renameusers) and field~*'reporter';
	update changeitem set OLDSTRING = (select newusername from renameusers where oldusername = OLDSTRING) where OLDSTRING in (select oldusername from renameusers) and field~*'reporter';
	update changeitem set NEWSTRING = (select newusername from renameusers where oldusername = NEWSTRING) where NEWSTRING in (select oldusername from renameusers) and field~*'reporter';


	-- Delete the duplicate userbase entries and group ownerships the above queries create
	delete from userbase u where exists (select * from userbase where username=u.username and id>u.id) ;
	delete from membershipbase u where exists (select * from membershipbase where user_name=u.user_name and group_name=u.group_name and id>u.id) ;
	-- Note: if both users had a custom dashboard, there will be two dashboards called 'Dashboard' with the same sequence, which JIRA might not like.
	-- Similarly there may be duplicate favouriteassociations

END;
$$ language plpgsql;

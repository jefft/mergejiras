-- Provides an indication of a user's interaction with JIRA by listing row counts for various tables a user might have
-- content in.
CREATE OR REPLACE VIEW userusages AS
	SELECT userbase.id, userbase.username, 
	(SELECT count(jiraissue.assignee) AS count
           FROM jiraissue
          WHERE jiraissue.assignee::text = userbase.username::text) AS assignees,
	( SELECT count(jiraissue.reporter) AS count
           FROM jiraissue
          WHERE jiraissue.reporter::text = userbase.username::text) AS reporters,
	( SELECT count(jiraaction.author) AS count
           FROM jiraaction
          WHERE jiraaction.author::text = userbase.username::text and actiontype='comment') AS comments,
	 ( SELECT count(*) from changegroup where changegroup.author=userbase.username) as changes,
	(SELECT count(*) AS count
	   FROM searchrequest
	  WHERE authorname=userbase.username OR searchrequest.username=userbase.username) as searchrequests,
	(SELECT count(*) AS count
	   FROM columnlayout
	  WHERE username=userbase.username) as columnlayouts,
	(SELECT count(*) AS count
	   FROM filtersubscription
	  WHERE username=userbase.username) as filtersubscriptions,
	(SELECT count(*) AS count
	   FROM portalpage
	  WHERE username=userbase.username) as portalpages,
	(SELECT count(*) AS count
	   FROM projectroleactor
	  WHERE roletypeparameter=userbase.username) as roletypeactors,
	(SELECT count(*) AS count
	   FROM favouriteassociations
	  WHERE username=userbase.username and entitytype='PortalPage') as favouriteportalpages,
	(SELECT count(*) AS count
	   FROM favouriteassociations
	  WHERE username=userbase.username and entitytype='SearchRequest') as favouritesearchrequests
   FROM userbase;
CREATE OR REPLACE VIEW activeusers AS select * from userusages WHERE (assignees+reporters+comments+changes+searchrequests+columnlayouts+favouriteportalpages+favouritesearchrequests+filtersubscriptions+portalpages+roletypeactors)>0;

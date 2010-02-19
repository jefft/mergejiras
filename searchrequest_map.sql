-- Find searchrequests converted from one set of IDs to the current database's by convertsearchrequests.rb, and
-- construct a map of old/new IDs. Result is a list of oldid:newid pairs:
--  oldid |  newid   
-- -------+----------
--  10372 | 12313796
--  10375 | 12313797
--  10760 | 12313805
--  ...
-- The marker template is "SearchRequest converted from OLDDB database, id OLDID"

CREATE OR REPLACE VIEW searchrequest_map AS SELECT regexp_replace(searchrequest.reqcontent, E'.*<!--SearchRequest converted from .* database, id (\\d+).*', E'\\1')::integer AS oldid, searchrequest.id as newid
   FROM searchrequest
  WHERE searchrequest.reqcontent ~~ '%SearchRequest converted from % database, id %'::text;

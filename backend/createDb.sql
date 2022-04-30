-- SQL Code for creating tables for the RE Cares 2021 Goodwill SAVE database

-- Version 2.0

-- Version 1.0., September 14, 2021
-- Version 2.0 Revision, September 26, 2021
--  Alex Dekhtyar, dekhtyar@calpoly.edu

-- Note: An effort is made to present the CREATE TABLE statements in 
--       as vanilla form as possible, however, I largely speak the
--       MySQL dialect these days, and am much less familiar with the
--       MS SQL Server or MS Access dialects.

--       As a result, if this document is used to actually create
--       tables in a relational database it needs to be thoroughly 
--       debugged.

-- Database design is based primarily on the E-R model constructed
-- in Summer 2021 and captured here: 
-- 

-- Version 1.0. E-R model document.
-- https://bit.ly/2WfQy2D


-- Version 2.0 E-R model Document:
-- https://bit.ly/3ocq5P3
 

-- RELATIONAL TABLES

-- Workers
-- Additional fields may be added per Goodwill recommendations


CREATE TABLE Workers(
workerID INT PRIMARY KEY, 
email VARCHAR(128) NOT NULL UNIQUE,
firstName VARCHAR(64),
lastName VARCHAR(64),
affiliation VARCHAR(128),
phone VARCHAR(20)
);

-- Worker Communications
CREATE TABLE W2WCommunications(
messageID INT PRIMARY KEY, 
from INT,  
timeStamp TIMESTAMP, 
messageText TEXT,
FOREIGN KEY(from) REFERENCES Workers(workerID)
);

-- Message Recipients
-- message can have multiple recipients, so we need many-to-one
-- table here

CREATE TABLE MessageRecipients(
messageID INT,
recipient INT
PRIMARY KEY(messageID, recipient),
FOREIGN KEY(messageID) REFERENCES W2WCommunications(messageID),
FOREIGN KEY(recipient) REFERENCES Workers(workerID)
);




-- Contacts
-- do we need contact info other than phone? (email, instagram, etc…)


CREATE TABLE Contacts(
contactID INT PRIMARY KEY, -- internal ID, add AUTOINCREMENT if can
firstName VARCHAR(64),
middleName VARCHAR(64),
lastName VARCHAR(64),
DoB DATE, -- available in MS SQL
race VARCHAR(32), -- contact's race - probably ENUM from
                  -- list provided by Goodwill
sex  VARCHAR(8), -- use "F", "M", and, if needed "Other"
setting VARCHAR(128), -- check with Goodwill once again what this is
notes TEXT, -- whatever comments Workers may need to associate
isDeceased INT, -- MS SQL has BOOL(EAN), but keeping it simple here.
                -- 0 = currently alive, 1 = contact is deceased
                -- ask Goodwill if they want some note on cause of 
                -- death - result of gun violence, or not (e.g.)
isAtRisk INT, -- MS SQL has BOOL(EAN), but keeping it simple here
              -- a flag to identify people who SAVE works with
              -- from other contacts SAVE workers might encounter
              -- 1 = at risk, 0 = not at risk.
              -- note: this is a life-time flag. Individual' current
              -- status may have changed, but if they were a client 
              -- of Goodwill SAVE this will always be set to 1
isActive INT  -- This is a dynamic flag. Only check if isAtRisk == 1
              -- 1 = currently active client
              -- 0 = current inactive client
              -- this avoids complex SQL for determining who is currently
              -- an active client
);

-- atRisk changes need to be tracked over time.
-- Contact Status - tracks the status of the Contact over time.

CREATE TABLE ContactStatus(
contactID INT,
statusUpdateDate DATE, -- date we changed the status of the contact
status INT, -- 0 = no longer active/not at risk
            -- 1 = at risk/active client of the program
note TEXT, -- a note related to the change of status
workerID, --  worker who changed the status
PRIMARY KEY(contactID, statusUpdateDate), -- one status change per day allowed
FOREIGN KEY(contactID) REFERENCES Contacts(contactID),
FOREIGN KEY(workerID) REFERENCES Workers(workerID)
);





-- in Version 2.0 ask Goodwill is they need any nicknames/street names 
-- tracked. Won't include in Version 1.0.

--- Multiple addresses of the contacts

CREATE TABLE ContactAddresses(
addressID INT PRIMARY KEY, -- AUTOINCREMENT if possible
contactID INT,
streetAddress VARCHAR(256), -- Just the street part
city VARCHAR(64),
state VARCHAR(2), -- use state codes
zip VARCHAR(10), 
isCurrent INT, -- 0 = not current address, 1 = current address.
UNIQUE(contactID, streetAddress), -- this is somewhat fuzzy key
                           -- using autoincremented ID to make things clean
FOREIGN KEY(contactID) REFERENCES Contacts(contactID)
);

--- Multiple Phone numbers of the contact 
CREATE TABLE ContactPhones(
contactID INT,
phone VARCHAR(20),
phoneType VARCHAR(64), -- cell, home
isCurrent INT, -- 0 = not current, 1 = current
PRIMARY KEY(contactID, phone), -- technically, multiple people 
FOREIGN KEY(contactID) REFERENCES Contacts(contactID)
);


-- Multiple Contact emails (just to keep all contact info similarly 
-- structured)

CREATE TABLE ContactEmails(
contactID INT,
email VARCHAR(20),
emailType VARCHAR(64), 
isCurrent INT, 
PRIMARY KEY(contactID, email),
FOREIGN KEY(contactID) REFERENCES Contacts(contactID)
);



-- multiple addresses
--- current address tag
--- multiple  phone numbers
-- Race
-- Hispanic ?

---- Pictures !!!!

--- Social Media Accounts of the contacts

CREATE TABLE ContactSocialMedia(
contactID INT,
platform VARCHAR(64), -- name of the social media platform
platformID VARCHAR(64), -- contact's userID on the platform
PRIMARY KEY (contactID, platform),
FOREIGN KEY(contactID) REFERENCES Contacts(contactID)
);

-- Contact Photographs
-- Photographs themselves are treated as assets on the server
-- the database stores filename and path to the image file
-- the server will take care of delivering the images when needed
-- no image data is stored directly in any database/ORM/back end.

CREATE TABLE ContactMedia(
contactID INT,
mediaType VARCHAR(10), -- "Image" or "Video" or "Audio" 
format VARCHAR(20), -- "PNG", "JPG", etc…
fullPath  VARCHAR(256), -- path to image on the server including filename
filename VARCHAR(256),  -- file name (separately, just for convenience)
path VARCHAR(256), -- path to the directory, no filename, (for convenience)
isProfilePic INT, -- when set to 1 (only one per contacT) - use as default 
-- profile picture.
altText VARCHAR(256), -- alt text for inclusive design
PRIMARY KEY(contactID, fullPath), -- individual photos may contain multiple
                    -- people in them (think of this as tagging)
FOREIGN KEY(contactID) REFERENCES Contacts(contactID)
);





-- Contact-to-Contact relationship
-- Emergency Contact information
-- Better to take a many-to-one approach here - this way we can 
-- store multiple emergency contacts per person.
-- In fact, we are going to combine Emergency Contacts with 
-- Contact-to-Contact connections

-- Note: this table is asymmetric, "connectedTo" --> "contactID"
-- connectedTo = "Mary Brown", contactID = "Steven Brown",
-- natureOfConnection = "mother" means
-- "Mary Brown is the mother of Steven Brown"
  

CREATE TABLE ContactConnections(
contactID  INT,
connectedTO INT,
natureOfConnection VARCHAR(256),  -- short list….
notes TEXT, -- not in the original spec, but a place for workers to
            -- put some long-form information
isEmergencyContact INT, -- could be BOOL
                        -- 1 = "connectedTo is an emergency contact
                        --     for "contactID"
isPrimaryEmergencyContact INT, -- same as isEmergencyContact, but only
                           -- one primary emergency contact per person
timeStamp DATE, -- record when the connection was established
PRIMARY KEY(contactID, connectedTo),
FOREIGN KEY(contactID) REFERENCES Contacts(contactID),
FOREIGN KEY(connectedTo) REFERENCES Contacts(contactID)
);

-- Primary workers working with the contact

CREATE TABLE ContactWorkers(
contactID INT,
workerID INT,
dateAssigned DATE, -- this will be an action performed in the
                   -- notetaking app, we record the date when it took place 
stopDates DATE, -- if a worker stops being a primary contact, include 
                -- non-empty stop date
PRIMARY KEY(contactID, workerID, startDate), -- this way same worker can be 
                -- associated with same contact multiple times over time
FOREIGN KEY(contactID) REFERENCES Contacts(contactId),
FOREIGN KEY(workerID) REFERENCES Workers(workerId)
);

-- Contact Probation Officers
CREATE TABLE ContactProbationOfficer(
contactID INT,
from DATE,
to DATE, -- possibly empty
isCurrent INT, -- 1 = current probation officer
officerFirstName VARCHAR(128),
officerLastName VARCHAR(128),
officerPhone VARCHAR(20),
officerEmail VARCHAR(256),
officerOffice VARCHAR(256), -- office where probation officer works
PRIMARY KEY(contactID, from), -- one officer at a time, multiple over time
FOREIGN KEY(contactID) references Contacts(contactID)
);

-- note: for now all probation officers are entered by hand, there is no
-- separate probation officer table. This might violate BCNF, but for this
-- particular corner of the DB we do not care.
-- In V.2.0 we may need to include a full list of probation officers as a 
-- separate table, and make ContactProbationOfficer the relationship set table
-- between Contacts and Probation officers


-- Groups

CREATE TABLE Groups(
groupID INT PRIMARY KEY, -- add AUTOINCREMENT if allowed
name VARCHAR(256) UNIQUE, -- might have to step away from UNIQUE
shortName VARCHAR(256), -- abbreviated name
mediaName VARCHAR(256), -- media name (Goodwill knows what it is)
dateEstablished DATE, -- exact date may not be known, so might need
                      -- a more forgiving type
                      -- may need a transaction timestamp too 
                      -- (date SAVE folks learned about it)
isActive INT, -- presumably a BOOL value actually:
              -- 0 = not active, 1 = active
              -- however, there may be edge cases so additional
              -- values are possible per Goodwill needs
isStreetGang INT, -- 1 = street gang, 0 = not a street gang
description VARCHAR(256),
notes TEXT,  -- additional notes associated with the group
);

-- Need to separate prior history of gang names from relationship between 
-- groups

CREATE TABLE GroupPriorNames(
groupID INT,
name VARCHAR(256),
shortname VARCHAR(128), -- abbreviated name
mediaName VARCHAR(256), -- media name matching previous gang name.
from DATE, -- date when the name became known
to DATE, -- date when the name changed to new name (or when Goodwill found out
         -- about name change)
PRIMARY KEY(groupID, from),  -- this assumes somewhat implicitly that
                             -- each street gang has only one name at a time.
FOREIGN KEY(groupID) REFERENCES Groups(groupID)
);


--- Non street gang groups require additional thoughtful treatment, but
--- in V. 1.0, we are keeping it simple. Will figure out later.
--- For now, just remember to test for "isStreetGang=1" whenever retrieving



-- Group Connections: now excludes renamings.
-- asymmetric

CREATE TABLE GroupConnections(
group1 INT,
group2 INT,
natureOfConnection VARCHAR(256),
from DATE,  -- might have to be "date when we found out about it"
to DATE,    -- might be "date when we found out"
notes TEXT,
PRIMARY KEY(group1, group2, from), -- only one connection between a pair of 
                       -- groups
FOREIGN KEY(group1) REFERENCES Groups(groupID),
FOREIGN KEY(group2) REFERENCES Groups(groupID)
);

--  names associated names, associated media names
--- this might be different than group v. group.

-- rival, partnerships, collaborator
-- affiliates of other groups
-- add dates

-- -Group Photos

CREATE TABLE GroupMedia(
groupID INT,
mediaType VARCHAR(10), -- "Image" or "Video" or "Audio"
format VARCHAR(20), -- "PNG", "JPG", etc…
fullPath  VARCHAR(256), -- path to image on the server including filename
filename VARCHAR(256),  -- file name (separately, just for convenience)
path VARCHAR(256), -- path to the directory, no filename, (for convenience)
isProfilePic INT, -- when set to 1 (only one per contacT) - use as default 
-- profile picture for group.
PRIMARY KEY(groupID, fullPath), -- individual photos may contain multiple
                    -- people in them (think of this as tagging)
FOREIGN KEY(groupID) REFERENCES Groups(groupID)
);


    
-- Cases

CREATE TABLE Cases(
caseID INT PRIMARY KEY, -- AUTOINCREMENT if allowed
                   -- this is internal case id assigned by the app
			   -- ask Goodwill if they want a police Case number
                   -- associated with the case here.

caseDate DATE,
caseTime TIME, -- date and time the incident occurred
description VARCHAR(256), -- short description of the case
numberOfVictims INT,
isGangRelated INT, -- serves as BOOL, 1="gang-related"
numberOfDeaths INT, -- number of victims who died as the result
                    -- of the incident
note TEXT, --long form note
enteredBy INT, -- tags the worker who entered the case info
caseTimestamp TIMESTAMP, -- time the Case was created
FOREIGN KEY(enteredBy) REFERENCES Workers(workerId)
);

-- press coverage…. link, 

-- multiple photos
-- contacts: social media profiles - multiple platforms…
-- Photos associated with case, case
-- Gang associated photos (tags)

CREATE TABLE CasePressCoverage(
articleID INT PRIMARY KEY, -- AUTOINCREMENT if possible
articleURL VARCHAR(1024), -- URL or article
source VARCHAR(256), -- name of site/publication
sourceType VARCHAR(64), -- newspaper, TV station, blog, etc…
sourceCoverage VARCHAR(64),  -- local/municipal, state, national, etc…
-- source type and coverage type are here for aggregation purposes
-- will make reporting easier.
caseID INT, -- case covered
FOREIGN KEY(caseID) REFERENCES Cases(caseID)
);




-- Incident type is many-to-many with Cases (so, a case may have many 
-- incident type tags associated with it)


-- may want a separate table of all possible incident type tags
-- but not certain if this is needed
-- For Version 1.0, keep the table as-is, no comprehensive list of labels
-- this means, Goodwill can add labels on the fly if they wanted to

CREATE TABLE IncidentType(
caseID INT,
incidentType VARCHAR(64), -- incident type tag
FOREIGN KEY(caseID) REFERENCES Cases(caseID),
PRIMARY KEY(caseID, incidentType)
);

-- Victims - there can be more than one
-- Use "Contacts" as the target table for victims
-- (i.e., a victim would have a record in the contacts table)

-- information about the victim w.r.t. case, but NOT in their 
-- contact record

CREATE Table IncidentVictims(
caseID INT,
victimID INT,
victimIsDeceased INT,
victimIsHospitalized INT,
hospital VARCHAR(128), -- can be empty
injuryDescription TEXT, -- description of injuries received
                        -- free form text for now, analytics will have to 
                        -- parse it
notes TEXT, -- long form notes
PRIMARY KEY(caseID, victimID),
FOREIGN KEY(caseID) REFERENCES Cases(caseID),
FOREIGN KEY(victimID) REFERENCES Contacts(contactID)
);

-- nature of injuries
-- follow-up - scheduled conversation
-- followup- alarm…


--- Case Media - images and videos associated with a case

CREATE TABLE CaseMedia(
caseID INT,
mediaType VARCHAR(10), -- "Image" or "Video" or "Audio"
format VARCHAR(20), -- "PNG", "JPG", etc…
fullPath  VARCHAR(256), -- path to image on the server including filename
filename VARCHAR(256),  -- file name (separately, just for convenience)
path VARCHAR(256), -- path to the directory, no filename, (for convenience)
caption VARCHAR(256), 
PRIMARY KEY(caseID, fullPath)
);




-- Note, we are tracking incident victims. We are not tracking 
-- perpetrators. This is something that never came up in
-- our conversations with Goodwill. They might decide that they want it
-- if the issue is raised, but we are freezing this for Version 1.0.
-- Version 2.0., if needed, can have a setup to track 
-- perpetrators as well.


-- Contacts and their associations with Groups and cases

-- Group Affiliation

CREATE TABLE contactAssociations(
contactID INT,
groupID INT,
associationDate DATE,
disassociationDate DATE, -- can be empty
natureOfAssociation VARCHAR(128),
timeStamp TIMESTAMP, -- time when we found out this information
notes TEXT, --long form notes
isActive INT, -- BOOL proxy - whether at present the association with                  
              -- group is active
PRIMARY KEY(contactID, groupID, associationDate), -- note: one person
            -- may have different associations with a group over time
            -- hence, need a third attribute for PK
FOREIGN KEY(contactID) REFERENCES Contacts(contactID),
FOREIGN KEY(groupID) REFERENCES Groups(groupID)
);


-- Contact Associations with Cases

CREATE TABLE Contact2Case(
contactID INT,
caseID INT,
role VARCHAR(256),
notes TEXT,
PRIMARY KEY(contactID, caseID),
FOREIGN KEY(contactID) REFERENCES Contacts(contactID),
FOREIGN KEY(caseID) REFERENCES Cases(caseID)
);

-- Group associations with Cases

CREATE TABLE Group2Case(
groupID INT,
caseID INT,
role VARCHAR(256),
notes TEXT,
PRIMARY KEY(groupID, caseID),
FOREIGN KEY(groupID) REFERENCES Groups(groupID),
FOREIGN KEY(caseID) REFERENCES Cases(caseID)
);

-- Referrals

CREATE TABLE Referrals(
referralID INT PRIMARY KEY, -- AUTOINCREMENT if allowed
source VARCHAR(256), -- org providing the referral
                     -- possibly an enum, but not clear
referredBy VARCHAR(256), -- name of a person
referralType VARCHAR(64), -- possibly an ENUM, check with Goodwill
referralDate DATE, 
notes TEXT, -- possibly information provided by the referral source
contactID INT, -- the person referred
enteredBy INT, -- worker who received/entered the referral
referralTimestamp, -- exact time when the entry was made
FOREIGN KEY(contactID) REFERENCES Contacts(contactID)
FOREIGN KEY(enteredBy) REFERENCES Workers(workerID)
);

-- Case to Referral connections
-- not all referrals are connected to cases. Also, not clear if 
-- a referral can be connected to multiple cases. So, keeping it
-- many-to-many relationship for now (see PRIMARY KEY constraint below)

CREATE TABLE Referrals2Case(
caseID INT,
referralID INT,
PRIMARY KEY(caseID, referralID),
FOREIGN KEY(caseID) REFERENCES Cases(caseID),
FOREIGN KEY(referralID) REFERENCES Referrals(referralID)
);




-- List of Social Services to which Goodwill SAVE clients 
-- can be referred.

CREATE TABLE SocialServices(
socialServiceID INT PRIMARY KEY, -- AUTOINCREMENT if possible
serviceName VARCHAR(256), -- service name
phone VARCHAR(20), --
liasonFirstName VARCHAR(64), -- first name of the Goodwill contact 
liasonLastName VARCHAR(64), -- last name of the Goodwill contact
email VARCHAR(256), -- service/liason email address
category VARCHAR(64), -- service category (possibly an ENUM)
description VARCHAR(256), -- what they do
streetAddress VARCHAR(256),
city VARCHAR(64),
state VARCHAR(2),
zip VARCHAR(16),
note TEXT
);


--  UNIFYING TABLE FOR ALL ACTIVITIES

CREATE TABLE Activities(
activityID INT PRIMARY KEY,
activityDate DATE, -- when it happened
activityCategory INT, -- could be an ENUM
                      -- 1 = Conversation, 2 = Intervention, 3 = Outreach
from TIME,
to TIME,
duration TIME, 
setting VARCHAR(128), -- location type for the activity
shortDescription VARCHAR(256), -- used as activity name
notes TEXT,
outcome VARCHAR(256), -- short description of event outcome 
actionItems TEXT, -- any outcomes/action items that workers need to record
                  -- separately from notes
activityMode VARCHAR(64), -- how this take place: "in person", "phone", "zoom"
activityType VARCHAR(64), -- "Custom", "Custom Notification", "Field contact"
                          -- Inferred from PowerBI
				  -- for interventions maps to intervention types
                          -- that Goodwill wants to track

reason VARCHAR(128),  -- reason for activity, 
                      -- for conversations: "self-intiated", "follow up", 
    -- "other", "recent violence"
    -- additional reasons possible for different activity 
    -- types
initiator INT,        --  1 = GoodWill, 0 = contact, 2 = community
attendance INT,       -- how many non-Godwill people participated:
                      -- for Conversations and Interventions can be 1 or
    -- actual number of contacts spoken to, for Outreach 
    -- events - number of people from signup sheets.
 
activityTimestamp,    -- time when this record was created
creator, -- Worker who created the Record (NOT TO BE CONFUSED WITH Worker 
         -- PARTICIPATION)
isScheduled INT, -- 1 = scheduled ahead of time, is on the calendar
                 -- 0 = not scheduled ahead of time
);


-- Workers to Activities

CREATE TABLE WorkerParticipation(
activityID INT,
workerID INT,
role VARCHAR(256),
PRIMARY KEY(activityID, workerID),
FOREIGN KEY(workerID) REFERENCES Workers(workerID),
FOREIGN KEY(activityID) REFERENCES Activities(activityID)
);

-- Contact Participation in Activities
-- this is not exhaustive for outreach activities
-- but should be exhaustive for conversations and interventions

-- Contacts to Activities
CREATE TABLE ContactParticipation(
activityID INT,
contactID INT,
contactType VARCHAR(256), -- for conversations:  talking to an 
                             -- influencer, person-at-risk, etc
                             -- might have meanings for 

role VARCHAR(256),
helpedOrganize INT, -- flag to indicate that the contact helped 
    -- organize the activity, not just participated
note TEXT,
PRIMARY KEY(activityID, contactID), 
FOREIGN KEY(contactID) REFERENCES Contacts(ContactID),
FOREIGN KEY(activityID) REFERENCES Activities(activityID)
);


-- Activities to Cases

CREATE TABLE CaseActivities(
activityID INT,
caseID INT,
associationType VARCHAR(256), -- how is this activity related to the case
                              -- (incident)
                              -- might contain "Victim followup" values
PRIMARY KEY(activityID, caseID)
FOREIGN KEY(activityID) REFERENCES Activities(conversationID),
FOREIGN KEY(caseID) REFERENCES Cases(CaseID)
);


-- Relationship between activities and referrals
-- mostly for Conversations and Interventions

CREATE TABLE Activity2Referral(
activityID INT,
referralID INT,
PRIMARY KEY(activityID, referralID),
FOREIGN KEY(activityID) REFERENCES Activities(activityID),
FOREIGN KEY(referralID) REFERENCES Referrals(referralID)
);


-- Social Service Referrals
-- These are primarily a result of interventions
-- there can be several of them as results of an intervention
-- We include contactID to identify who specifically was referred
-- as participation in activities is now many-to-many for all types
-- of activity

CREATE TABLE OutsideReferrals(
referralID INT PRIMARY KEY, --AUTOINCREMENT If possible
workerID INT, -- worker who makes the referral 
contactID INT, -- contact for whom the referral is made
activityID INT, -- what activity prompted this referral
		    -- (usually an Intervention, but perhaps others as well)
socialServiceID INT, -- Social Service the contact is referred to
referralDate DATE, -- when referred
notes TEXT,
FOREIGN KEY(workerID) REFERENCES Workers(workerID),
FOREIGN KEY(contactID) REFERENCES Contacts(contactID),
FOREIGN KEY(activityID) REFERENCES Activities(activityID),
FOREIGN KEY(socialServiceID) REFERENCES SocialServices(socialServiceID)
);


-- "Nice Things" (CommunityService) done at different outreach events
-- this is broadly defined (e.g., "distributed 120 pizzas" or "gave a gift $10 
-- grocery store gift card", or even "paid for uber ride home")
-- there is description of the "nice thing", a multiple for how many were 
-- provided (120 pizzas, 1 ride home), and the monetary impact of a single 
-- "nice thing" and all the nice things provided 
-- (typically overall impact = impact of one item x number of items, but there 
--  may be weird edge cases)

CREATE TABLE CommunityService(  -- rename to CommunityService 
 logID INT PRIMARY KEY, -- AUTOINCREMENT
 activityID INT, activity
 description VARCHAR(256), -- what was distributed/provided
 quantity INT, -- quantity of "nice thing" provided, can be 1 if
               -- done something for a single individual
 valueOfUnit FLOAT, -- dollar value of one "nice thing"
 totalValue FLOAT, -- dollar value of the entirety of "nice things" provided
 valueOverride INT, --  1 = totalValue != valueOfUnit * quantity
                    --  0 = totalValue = valueOfUnit * quantity
 notes TEXT,
 FOREIGN KEY(activityID) REFERENCES Activities(activityID)
); 




--- REsources need to captured

--  name of social service
--  contact information
--  name
--  phone
-- email
--  physical address
--  summary of what they do (drop down list)
--  note
--  


-- Miles Traveled.
-- The concept here is that there is a set of miles traveled
-- records associated with workers, and there are connector 
-- tables relating these records to conversations, cases,
-- interventions, and outreach activities.

CREATE TABLE MilesTravelled(
mtID INT PRIMARY KEY, -- let's give it a proper primary key 
                      -- to avoid issues
travelDate DATE, 
from TIME, -- time travel started
to TIME,   -- time travel ended (these can be approximate)
miles FLOAT,
purpose VARCHAR(32), -- could be ENUM
             -- "Conversation", "Intervention", "Outreach Activity"
             -- this will simplify some aggregations 
note TEXT,
--- FOREIGN KEY(workerID) REFERENCES Workers(workerID)
);


-- miles to workers. If several people travel together
-- we need to be able to separate "total miles traveled"
-- vs "person-miles traveled"
CREATE TABLE WorkerMiles(
mtID INT,
workerID INT,
isDriver INT,  -- 1 = driver, 0 = passenger, 2 = shared
isVehicleOwner INT, -- 1 = used own vehicle, not certain if needed
PRIMARY KEY(mtID, workerID),
FOREIGN KEY(mtID) REFERENCES MilesTravelled(mtID),
FOREIGN KEY(workerID) REFERENCES Workers(workerID)
);


-- Relationship between miles traveled and activities
-- this can be a many-to-many (i.e., the same miles can count
-- towards multiple activities), which is why this is a 
-- separate table

CREATE TABLE ActivityMiles(
mtID INT,
activityID,
PRIMARY KEY(mtID, activityID), -- want to be flexible - same miles 
-- could have been for multiple events.
FOREIGN KEY(mtID) REFERENCES MilesTravelled(mtID),
FOREIGN KEY(activityID) REFERENCES Activities(activityID)
);

-- miles traveled for a Case
-- A Case is not an activity, and some miles traveled for a Case
-- may not be attributable to specific activities, so this is separate

CREATE TABLE CaseMiles(
mtID INT,
caseID,
PRIMARY KEY(mtID, caseID), -- want to be flexible - same miles 
-- could have been for multiple cases.
FOREIGN KEY(mtID) REFERENCES MilesTravelled(mtID),
FOREIGN KEY(caseID) REFERENCES Cases(caseID)
);

--  GEOGRAPHIC INFORMATION

-- Many different objects and events in the DB have geography 
--- associated with it. We are using GeJSON as the underlying format
--- and the GEOGRAPHY data type of represent the appropriate
--- Geolocation information
--- In some cases, addresses are available alongside geolocation info
--- in such cases, it is possible that one or the other are empty
--- We can always back-fill geolocation from an address
--- the inverse might not be true

-- Worker Tracking and Locations
-- When worker tracking is engaged, every X seconds (X defined in 
-- application) worker's location will be recorded.
-- We use two tables. One to start end tracking (this is used to 
-- compute time worked), one to record locations.

CREATE TABLE WorkerTracking(
trackId INT PRIMARY KEY, -- AUTOINCREMENT
workerID INT,
trackDate DATE,   -- DATEONLY in some flavors
trackStartTime TIMESTAMP, 
isCurrent INT, -- if set to 1, trackEndDate will be empty
purpose VARCHAR(256), -- what the worker is/was doing
notes TEXT, -- notes from this time
trackEndTime TIMESTAMP,
trackEndDate DATE -- DATEONLY in some flavors 
FOREIGN KEY(workerID) REFERENCES Workers(workerID)
);

-- Geolocation of Workers

CREATE TABLE WorkerLocations(
workerID INT,
trackID INT,
snapshotTime TIMESTAMP,
workerLocation GEOMETRY, -- GeoJSON object of type POINT
PRIMARY KEY(workerID, snapshotTime), -- change to UNIQUE if adding
               -- an autoincrement key
FOREIGN KEY(workerID) REFERENCES Workers(workerID),
FOREIGN KEY(trackID) REFERENCES WorkerTracking(trackID)
);

-- Distress Signals - here we combine time and location
-- We also allow for distress signal to be inactivated

CREATE TABLE DistressSignals(
signalID INT PRIMARY KEY, -- AUTOINCREMENT
trackID INT,
workerID INT,
activationTime TIMESTAMP,
signalLocation GEOMETRY,
isActive INT, -- 1 = currently active
		   -- 0 = deactivated by worker
description VARCHAR(256), -- filled post-factum, short description
               -- of what happened
notes TEXT, -- filled post-factum, long-form notes
deactivationTime TIMESTAMP, -- notetaking app will have to be smart 
                 -- enough to recognize what signal to deactivate
UNIQUE(workerID, activationTime), -- there really should not be
                 -- multiple distress signals from one person at same 
 -- time
FOREIGN KEY(workerID) REFERENCES Workers(workerID),
FOREIGN KEY(trackID) REFERENCES WorkerTracking(trackID)
);


-- Group: area of activity
-- This can apply to both gangs, and other groups - e.g., we can
-- store school district information, location of a church/parish, 
-- etc...

-- Treating this as snapshot info, this way, we can record changes
-- over time

CREATE TABLE GroupActiveArea(
groupID INT,
areaDate DATE, -- probably don't need the actual time here
itCurrent INT, -- whether this is current geography for this group
               -- 1 = yes, 0 = no
location GEOMETRY, -- largely polygons, but just in case we can add a 
  -- flag 
locationType INT, -- or ENUM; 0 = polygon, 1 = point, 2 = other
notes TEXT, -- notes on this entry
PRIMARY KEY(groupID, areaDate), -- replace with UNIQUE if adding
                -- an autoincremented ID 
FOREIGN KEY(groupID) REFERENCES groups(groupID)
);

-- Case relationship to locations
-- this is more sophisticated. 
-- In a simple situation, one location is associated with a case,
-- and it can be either an address or a point, or both.
-- In more complex situations, there may be multiple locations 
-- (points)/addresses
-- Finally, in some cases, these can be also backed up by a 
-- polygon

CREATE TABLE CaseLocations(
caseID INT,
caseLocationOrdinal INT, -- basically enumerating locations associated 
			-- with a case: Case Location 1, Case Location 2, 
-- etc..
location GEOMETRY,
locationType, -- 0 = polygon, 1 = point, 2 = other
addedOn TIMESTAMP, -- transaction time for when the location was added
occurrenceTime TIMESTAMP, -- validity time for when something happened 
    -- there
streetAddress VARCHAR(256), -- Just the street part
city VARCHAR(64),
state VARCHAR(2), -- use state codes
zip  VARCHAR(10), -- adding zip codes just in case
                  -- helps with stats as well (break stuff by zip)
isAddress INT, -- 1 = address included, 0 = no address
PRIMARY KEY(caseID, caseLocationOrdinal), -- must be turned into UNIQUE if
             -- autoincremented ID is added
FOREIGN KEY(caseID) REFERENCES Cases(caseID)
);

-- Activity Locations
-- most activities may require only one location, but
-- some activities might need more, so let's be generic about it

CREATE TABLE ActivityLocations(
activityID INT,
activityLocationOrdinal INT, -- basically enumerating locations 
-- associated with an activity: 
-- Location 1, Location 2, etc..
location GEOMETRY,
locationType, -- 0 = polygon, 1 = point, 2 = other (line segments)
PRIMARY KEY(activityID, activityLocationOrdinal), -- turn to UNIQUE
                -- if using autoincremented ID
FOREIGN KEY(activityID) REFERENCES OutreachActivities(activityID)
);


--- RANDOM NOTES BELOW - KEPT FOR POSTERITY



-- probation officer info, name, phone , email
-- possibly a table 


--- primary outreach worker assignment. possibly multiple...


--  tool tips for things ???

-- alarms for outreach activities….



--- user access control
---  outreach workers assigned different access permissions  
---  based on what they worked on.

---  implemented as a list of checkboxes to various 
--- piece of functionality.

-- Director role
-- Administrator role
--- Outreach worker role → somrasboard of access permissions
-- guest role   -> preset set of permissions with some additional 
--                 access options.

#!/usr/bin/env python

#==============================================================================
# Title:				ucsdServiceRequest
# Description:			This script uses the UCSD API to pull the status of 
#						the service requests that have been raised
# Author:          		Rob Edwards (robedwa)
# Date:		            04/11/14
# Version:				0.2
# Dependencies:			prettytable module ('sudo easy_install prettytable')
# Limitations/issues:	Need to finish error checking 
#==============================================================================

import httplib
import json
from prettytable import PrettyTable

# --- Variables ---
uscdServer = "ukidcv-cucsd.cisco.com"
headers = {"X-Cloupia-Request-Key":"C413E849B0384BDD8EE38EEDA9CB6383"}
userAPIGetTabularReport = "/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%226%22,param1:%22%22,param2:%22SERVICE-REQUESTS-T10%22%7D"
userAPIGetWorkflowStatus = "/app/api/rest?formatType=json&opName=userAPIGetWorkflowStatus&opData=%7Bparam0%3A43%7D"

# --- Functions ---
def apiCall(api):
	connection = httplib.HTTPConnection(uscdServer, 80, timeout = 30)
	connection.request('GET', api, None, headers)

	try:
		response = connection.getresponse()
		content = response.read()
		#print('Response status ' + str(response.status))	#Left in for logging purpose
		return content	

	except httplib.HTTPException, e:
	 	print('Exception during request')	# Need to finish error checking


TabularReportReturn = apiCall(userAPIGetTabularReport)	
					

# Convert JSON string to Dictionary
TabularReportResult = json.loads(TabularReportReturn)


TabularReportValues = TabularReportResult["serviceResult"]
rows = TabularReportValues["rows"]

# --- Main ---
table = PrettyTable(["ID", "Catalog", "Status", "Comment", "User"])
table.align["City name"] = "l" # Left align city names
table.padding_width = 1 # One space between column edges and contents (default)

for item in rows:
	a = item["Service_Request_Id"]
	b = item["Catalog_Workflow_Name"]
	c = item["Request_Status"]
	d = item["Initiator_Comments"]
	e = item["Initiating_User"]

	table.add_row([a, b, c, d, e])

print table

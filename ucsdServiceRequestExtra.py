#!/usr/bin/env python

#==============================================================================
# Title:				ucsdServiceRequest
# Description:			This script uses the UCSD API to pull the status of 
#						the service requests that have been raised.
#						It will also pull the status from a seperate API.
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
		#print('Response status ' + str(response.status))	
		return content	

	except httplib.HTTPException, e:
	 	print('Exception during request')	


TabularReportReturn = apiCall(userAPIGetTabularReport)						
TabularReportResult = json.loads(TabularReportReturn)
TabularReportValues = TabularReportResult["serviceResult"]
rows = TabularReportValues["rows"]

# --- Main ---
table = PrettyTable(["ID", "Catalog", "Status", "Extra Status", "Comment", "User"])
table.align["City name"] = "l" # Left align city names
table.padding_width = 1 # One space between column edges and contents (default)

for item in rows:
	a = item["Service_Request_Id"]
	b = item["Catalog_Workflow_Name"]
	c = item["Request_Status"]
	d = item["Initiator_Comments"]
	e = item["Initiating_User"]

	WorkflowStatusReturn = apiCall("/app/api/rest?formatType=json&opName=userAPIGetWorkflowStatus&opData=%7Bparam0%3A" + str(a) + "%7D")
	WorkflowStatusResult = json.loads(WorkflowStatusReturn)
	status = WorkflowStatusResult["serviceResult"]

	if status == 0 :
		cc = "Not Started"
	elif status == 1:
		cc = "In Progess"
	elif status == 2:
		cc = "Failed"
	elif status == 3:
		cc = "Complete"
	elif status == 4:
		cc = "Complete with warning(s)"
	elif status == 5:
		cc = "Cancelled"
	else:
		cc = "Unknown"

	table.add_row([a, b, c, cc, d, e])

print table

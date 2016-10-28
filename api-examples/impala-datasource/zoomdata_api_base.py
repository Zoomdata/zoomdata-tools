#!/usr/bin/env python
import sys,urllib,urllib2,json

class HttpServerRequest(object):
  # HTTP Server request class
  debug=False
  debugLevel=1

  def __init__(self):
    """Return a request object """
    self.authHeader = None

  def __openrequest__(self, req):
    # Opens the passed in HTTP request
    if self.debug:
      print "\n----- REQUEST -----"
      handler = urllib2.HTTPSHandler(debuglevel=self.debugLevel)
      opener = urllib2.build_opener(handler)
      urllib2.install_opener(opener)
    
    res = urllib2.urlopen(req)
    out = res.read()

    if self.debug:
      print "\n----- REQUEST INFO -----"
      print res.info()
      print "\n----- RESPONSE -----"
      print out

    return out

  def submit(self,url,data=None,lmda=None,type=None):
    # Constructs the HTTP server request
    
    if data != None:
        # Add data payload to request
        request = urllib2.Request(url, data) #PUT/POST
        
        if type != None:
          # Set payload content type
          request.add_header('Content-Type', type)
        else:
          # Default payload content type
          request.add_header('Content-Type', 'application/json')
    else:
      # Assume GET request
      request = urllib2.Request(url) #GET

    if self.authHeader != None:
      # Add authentication header if present
      request.add_header('Authorization', self.authHeader)

    if lmda != None:
      # Set request method: PATCH, DELETE, etc
      request.get_method = lambda: lmda

    return self.__openrequest__(request)

  def enableDebug(self, level=1):
    # Enable verbose output of HTTP request transmission
    self.debug=True
    self.debugLevel=level
  
  def disableDebug(self):
    # Disable verbose output of HTTP request transmission
    self.debug=False

class ZoomdataRequest(HttpServerRequest):
  # Zoomdata HTTP Server request class

  def __init__(self, zoomdataBaseURL, adminUser, adminPassword, supervisorUser=None, supervisorPassword=None):
    """Return a Zoomdata server HTTP request object """
    self.adminUser = adminUser
    # Encode the admin credentials
    self.adminAuthHeader = self.__encodeAuthHeader__(adminUser,adminPassword)
    # Encode the supervisor credentials (if present)
    if supervisorPassword is not None:
      self.supervisorAuthHeader = self.__encodeAuthHeader__(supervisorUser,supervisorPassword)
    # Initialize the Zoomdata server URL
    self.zoomdataServer = zoomdataBaseURL
    
    # Default to admin authentication
    self.useAdminAuth()

  def __encodeAuthHeader__(self, user, password):
    # Return encoded credentials to be used on the HTTP request
    return "Basic " + (user+":"+password).encode("base64").rstrip()

  def useAdminAuth(self):
    # Authenticate to Zoomdata as an administrator (tenant-level)
    self.authHeader = self.adminAuthHeader

  def useSupervisorAuth(self):
    # Authenticate to Zoomdata as the 'supervisor' (instance-level)
    self.authHeader = self.supervisorAuthHeader

  def getCurrentAuthUser(self):
    # Return current auth configuration
    if self.authHeader == self.adminAuthHeader:
      return self.adminUser
    else:
      return "supervisor"

class ZoomdataObject(object):
  # Base Zoomdata metadata + server request object
  def __init__(self, name, serverRequest):
    self.id = ""
    self.name = name
    self.serverRequest = serverRequest
    self.apiEndpoint = ""

  def initPayload(self, fileName):
    try:
      with open(fileName,"r+") as f:
        self.payload = json.load(f)

    except:
      print "* File "+fileName+" could not be read" 
      raise

  def submit(self, customEndpoint=None):
    if customEndpoint is None:
      apiEndpoint = self.apiEndpoint
    else:
      apiEndpoint = customEndpoint

    data = json.dumps(self.payload)
    #print data
    return json.loads(self.serverRequest.submit(apiEndpoint,data=data))

  def create(self):
    # Create the object in Zoomdata and record the assigned ID
    self.id = self.submit()["id"]

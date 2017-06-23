# CONFIRM_CODE = '4/NRTLGVYKfDRI0jCBgNyb2Jv1aSbSf3O7MKWP32cfbGk'
googleAPIfile = Meteor.root+'/googleapis.json'
Fiber    = require 'fibers'
fs       = require 'fs'
readline = require 'readline'
google   = require 'googleapis'
googleAuth = require 'google-auth-library'
# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/drive-nodejs-quickstart.json
# SCOPES = [ 'https://www.googleapis.com/auth/drive.metadata.readonly' ]
SCOPES = [ 'https://spreadsheets.google.com/feeds', 'https://docs.google.com/feeds','https://www.googleapis.com/auth/drive.file']
# TOKEN_DIR = (process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE) + '/.credentials/'
TOKEN_DIR = Meteor.root + '/.google'
TOKEN_PATH = TOKEN_DIR + '/api_token.json'
# Load client secrets from a local file.


authorize = (callback) ->
  setTimeout =>

    fs.readFile googleAPIfile, (err, credentials) ->
      
      if err
        console.log 'Error loading client secret file: ' + err
        return
      credentials = JSON.parse(credentials)
      clientSecret = credentials.installed.client_secret
      clientId = credentials.installed.client_id
      redirectUrl = credentials.installed.redirect_uris[0]
      auth = new googleAuth
      oauth2Client = new (auth.OAuth2)(clientId, clientSecret, redirectUrl)
      # Check if we have previously stored a token.
      fs.readFile TOKEN_PATH, (err, token) ->
        if err
          getNewToken oauth2Client, callback
        else
          oauth2Client.credentials = JSON.parse(token)
          callback oauth2Client

  , 300

getNewToken = (oauth2Client, callback, code) ->
  Fiber ->

    # code = Mongo.Tmp.findOne('google')?.apiCode
    # if code is undefined then Mongo.Tmp.insert _id: 'google', apiCode: null

    authUrl = oauth2Client.generateAuthUrl access_type: 'offline', scope: SCOPES
    # unless CONFIRM_CODE?
    #   console.log 'Authorize this app by visiting this url: ', authUrl
    # else
    oauth2Client.getToken code, (err, token) ->
      if err
        
        root = process.env.MOBILE_ROOT_URL
        path = '/google_api_key'
        url = root+path.replace('//google', '/google')
        Meteor.registeredUrls ?= []
        Meteor.registeredUrls.push path
        WebApp.connectHandlers.use path, (req, res, next) ->
          code = req.originalUrl.replace path+'/', ''
          if code.length
            res.writeHead 200; res.end 'ok'
            getNewToken oauth2Client, callback, code
          else
            res.writeHead 400; res.end 'no'
        console.log 'Authorize this app by visiting this url: ', authUrl
        console.log "And then visit #{url}/{token}"
        return
        
      
      oauth2Client.credentials = token
      storeToken token
      callback oauth2Client
  .run()


storeToken = (token) ->
  try
    fs.mkdirSync TOKEN_DIR
  catch err
    if err.code != 'EEXIST'
      throw err
  fs.writeFile TOKEN_PATH, JSON.stringify(token)
  console.log 'Token stored to ' + TOKEN_PATH
  return

module.exports = authorize

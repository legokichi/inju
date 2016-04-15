fs         = require("fs")
bodyParser = require('body-parser')
multiparty = require("multiparty")
express    = require('express')
http       = require('http')

__PORT_NUMBER__ = 8083
__HTTPS_OPTIONS__ =
  key:  try fs.readFileSync('ssl/privateKey.pem')  catch err then null
  cert: try fs.readFileSync('ssl/certificate.pem') catch err then null

app = express()
if __HTTPS_OPTIONS__.key? && __HTTPS_OPTIONS__.cert?
then server = https.createServer(__HTTPS_OPTIONS__, app)
else server = http.createServer(app)


app.use(bodyParser.urlencoded({ extended: true }))
app.use(bodyParser.json())

app.use('/',                 express.static(__dirname + '/demo'))
app.use('/bower_components', express.static(__dirname + '/bower_components'))
app.use('/lib',              express.static(__dirname + '/lib'))
app.use('/nar',              express.static(__dirname + '/nar'))
app.use('/dist',             express.static(__dirname + '/dist'))


res204 =  (fn)-> (req, res)-> setTimeout(-> fn(req, res)); res.sendStatus(204)

app.get '/all',    res204 -> startAll()

server.listen(__PORT_NUMBER__)

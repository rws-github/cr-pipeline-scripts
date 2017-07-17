/** ******************************************************** {COPYRIGHT-TOP} ****
* Licensed Materials - Property of IBM
*
* (C) Copyright IBM Corp. 2016 All Rights Reserved
*
* US Government Users Restricted Rights - Use, duplication, or
* disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
********************************************************* {COPYRIGHT-END} ****/
var async = require('async')
var childProcess = require('child_process')
var colors = require('colors/safe')
var fs = require('fs')

var parseCfAppEnvVars = function (cfApp, callback) {
  // construct a JSON array string from the system provided env vars
  var systemProvidedContent = '['
  var recordingSystemProvided = false
  var recordingUserProvided = false
  console.log('Reading environment variables for app %s to get Cloudant information', cfApp)
  var cfEnvProc = childProcess.spawn('cf', [ 'env', cfApp ])
  cfEnvProc.stderr.on('data', function (data) {
    console.error(data)
  })
  cfEnvProc.on('close', function (cfEnvExitCode) {
    if (cfEnvExitCode !== 0) {
      callback(new Error("Error executing 'cf env' to get Cloudant information, exit code: " + cfEnvExitCode))
    } else {
      // console.log(systemProvidedContent);
      systemProvidedContent = systemProvidedContent.substr(0, systemProvidedContent.lastIndexOf(',')) + ']'
      var jsonEnv = JSON.parse(systemProvidedContent)
      for (var i = 0; i < jsonEnv.length; i++) {
        if (jsonEnv[i].VCAP_SERVICES) {
          process.env.VCAP_SERVICES = JSON.stringify(jsonEnv[i].VCAP_SERVICES)
        } else if (jsonEnv[i].VCAP_APPLICATION) {
          process.env.VCAP_APPLICATION = JSON.stringify(jsonEnv[i].VCAP_APPLICATION)
        }
      }
      callback(null)
    }
  })
  var lineReader = require('readline').createInterface({
    terminal: false,
    input: cfEnvProc.stdout
  })
  lineReader.on('line', function (line) {
    var trimmedLine = line.trim()
    if (trimmedLine === 'System-Provided:') {
      // start recording
      recordingSystemProvided = true
    } else if (recordingSystemProvided) {
      if (trimmedLine === 'User-Provided:') {
        recordingSystemProvided = false
        recordingUserProvided = true
      } else if (trimmedLine !== '') {
        systemProvidedContent += line + (line.indexOf('}') === 0 ? ',\n' : '\n')
      }
    } else if (recordingUserProvided) {
      if (trimmedLine === 'Running Environment Variable Groups:') {
        recordingUserProvided = false
      } else {
        var separatorIndex = trimmedLine.indexOf(':')
        if (separatorIndex > 0) {
          var userProvidedName = trimmedLine.substr(0, separatorIndex)
          var userProvidedValue = trimmedLine.substr(separatorIndex + 1).trim()
          process.env[userProvidedName] = userProvidedValue
        }
      }
    }
  })
}

var checkIfDatabaseExists = function (url, databaseName, callback) {
  const Cloudant = require('cloudant')
  const cloudant = Cloudant({ url: url })
  cloudant.db.get(databaseName, function (err, body) {
    if (err) {
      if (err.error === 'not_found') {
        // database does not exist
        callback(null, false)
      } else {
        // unknown error - can not determine database state
        callback(err)
      }
    } else {
      // database exists
      callback(null, true)
    }
  })
}

var createDatabase = function (url, databaseName, callback) {
  const Cloudant = require('cloudant')
  const cloudant = Cloudant({ url: url })
  cloudant.db.create(databaseName, function (err) {
    if (err) {
      callback(err)
    } else {
      callback(null, true)
    }
  })
}

var deleteDatabase = function (url, databaseName, callback) {
  const Cloudant = require('cloudant')
  const cloudant = Cloudant({ url: url })
  cloudant.db.destroy(databaseName, function (err) {
    if (err) {
      callback(err)
    } else {
      callback(null, true)
    }
  })
}

var directoryExists = function (path) {
  try {
    return fs.statSync(path).isDirectory()
  } catch (e) {
    return false
  }
}

var updateDesignDocs = function (url, databaseName, designDirPath, callback) {
  if (directoryExists(designDirPath)) {
    console.log(colors.magenta('Migrating Cloudant design documents of database %s'), databaseName)
    var designDocFileName = fs.readdirSync(designDirPath)
    // files is an array of the names of the files in the directory excluding '.' and '..'
    if (!designDocFileName || designDocFileName.length === 0) {
      console.log('No design documents to migrate')
    } else {
      var spawnEnv = {}
      for (var envVarName in process.env) spawnEnv[envVarName] = process.env[envVarName]
      spawnEnv.COUCH_URL = url
      var spawnOpts = {
        stdio: 'inherit',
        env: spawnEnv
      }
      async.eachSeries(designDocFileName, function (designDocFileName, callback) {
        var designDocFilePath = designDirPath + '/' + designDocFileName
        console.log('\nUpdating Cloudant database %s with design doc %s', databaseName, designDocFilePath)
        // Usage: node ./node_modules/.bin/couchmigrate --dd <design document filename> --db <name of database>
        var migrateResult = childProcess.spawnSync('node',
          [ './node_modules/couchmigrate/bin/couchmigrate.bin.js', '--dd', designDocFilePath, '--db', databaseName ],
          spawnOpts
        )
        if (migrateResult.error) {
          console.error(colors.red('Migration of design doc %s failed'), designDocFilePath)
          console.error(colors.red('%s'), migrateResult.error)
          process.exit(1)
        } else if (migrateResult.status !== 0) {
          console.error(colors.red('Migration of design doc %s failed with exit code %s'), designDocFilePath, migrateResult.status)
          process.exit(colors.red('%s'), migrateResult.status)
        } else {
          async.setImmediate(function () {
            callback(null, designDocFileName)
          })
        }
      }, callback)
    }
  }
}

var createQueryIndexes = function (url, databaseName, queryDirPath, callback) {
  const Cloudant = require('cloudant')
  const cloudant = Cloudant({ url: url })
  const db = cloudant.db.use(databaseName)

  var queryFileName = fs.readdirSync(queryDirPath)
  // files is an array of the names of the files in the directory excluding '.' and '..'
  if (!queryFileName || queryFileName.length === 0) {
    console.log('\nNo query indexes to update')
  } else {
    async.eachSeries(queryFileName, function (queryDocFileName, callback) {
      var queryDocFilePath = queryDirPath + '/' + queryDocFileName

      console.log('\nUpdating Cloudant database %s with query index %s', databaseName, queryDocFilePath)
      var data = fs.readFileSync(queryDocFilePath)
      console.log('## get all query indexes to check if it already exists')
      db.index(function (err, result) {
        console.log('  err = %s', err)
        console.log('  data = %s', JSON.stringify(result))
        var found = false
        result.indexes.forEach((index) => {
          if (index.ddoc === '_design/' + queryDocFileName.substr(0, queryDocFileName.lastIndexOf('.'))) {
            found = true
            console.log('## query index already exists, getting _rev to delete')
            db.get(index.ddoc, function (err, body) {
              console.log('  err = %s', err)
              console.log('  data = %s', JSON.stringify(body))
              console.log('## delete old query index')
              db.destroy(body._id, body._rev, function (err, result) {
                console.log('  err = %s', err)
                console.log('  data = %s', JSON.stringify(result))
                console.log('## create new query index - %s', data.toString())
                db.index(data, function (er, response) {
                  console.log('  err = %s', err)
                  console.log('  data = %s', JSON.stringify(response))
                  console.log('-------------------------------')
                  console.log('Query index %s creation result: %s', queryDocFilePath, response.result)
                  async.setImmediate(function () {
                    callback(null, queryDocFileName)
                  })
                })
              })
            })
          }
        })
        if (!found) {
          console.log('## query index not present, creating new query index - %s', data.toString())
          db.index(data, function (er, response) {
            console.log('  err = %s', err)
            console.log('  data = %s', JSON.stringify(response))
            console.log('-------------------------------')
            console.log('Query index %s creation result: %s', queryDocFilePath, response.result)
            async.setImmediate(function () {
              callback(null, queryDocFileName)
            })
          })
        }
      })
    }, callback)
  }
}

module.exports.parseCfAppEnvVars = parseCfAppEnvVars
module.exports.checkIfDatabaseExists = checkIfDatabaseExists
module.exports.createDatabase = createDatabase
module.exports.deleteDatabase = deleteDatabase
module.exports.directoryExists = directoryExists
module.exports.updateDesignDocs = updateDesignDocs
module.exports.updateQueryIndexes = createQueryIndexes

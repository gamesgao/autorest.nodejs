require './common.iced'

# ==============================================================================
# tasks required for this build 
Tasks "dotnet"  # dotnet functions
Tasks "regeneration"
Tasks "publishing"

# ==============================================================================
# Settings
Import
  initialized: false
  solution: "#{basefolder}/autorest.nodejs.sln"
  sourceFolder:  "#{basefolder}/src/"

# ==============================================================================
# Tasks

task 'init', "" ,(done)->
  Fail "YOU MUST HAVE NODEJS VERSION GREATER THAN 7.10.0" if semver.lt( process.versions.node , "7.10.0" )
  await execute "npm install", { cwd: './test/vanilla' }, defer code, stderr, stdout
  await execute "npm install", { cwd: './test/azure' }, defer code, stderr, stdout
  done()
  
# Run language-specific tests:
task 'build', 'tests', ['init'], (done) ->
  await execute "npm run build", { cwd: './test/vanilla' }, defer code, stderr, stdout
  await execute "npm run build", { cwd: './test/azure' }, defer code, stderr, stdout
  done();

task 'test', '', ['build/tests'], (done) ->
  await execute "npm test", { cwd: './test/vanilla/' }, defer code, stderr, stdout
  await execute "npm test", { cwd: './test/azure/' }, defer code, stderr, stdout
  done();

# CI job
task 'testci', "more", [], (done) ->
  # install latest AutoRest
  await autorest ["--latest"], defer code, stderr, stdout

  ## TEST SUITE
  global.verbose = true
  await run "test", defer _

  ## REGRESSION TEST
  global.verbose = false
  # regenerate
  await run "regenerate", defer _
  # diff ('add' first so 'diff' includes untracked files)
  await  execute "git add -A", defer code, stderr, stdout
  await  execute "git diff --staged -w", defer code, stderr, stdout
  # eval
  echo stderr
  echo stdout
  throw "Potentially unnoticed regression (see diff above)! Run `npm run regenerate`, then review and commit the changes." if stdout.length + stderr.length > 0
  done() 
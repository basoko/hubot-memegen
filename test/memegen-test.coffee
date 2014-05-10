chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

expect = chai.expect

describe 'memegen', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
      logger:
        debug: sinon.spy()
        info: sinon.spy()
        warning: sinon.spy()
        error: sinon.spy()

    require('../src/memegen.coffee')(@robot)

  it 'registers a respond listener for "create meme"', ->
    expect(@robot.respond).to.have.been.calledWith(/memegen (.*?) (.*)$/i)

  it 'registers a respond listener for "list available templates"', ->
    expect(@robot.respond).to.have.been.calledWith(/memegen list templates$/i)

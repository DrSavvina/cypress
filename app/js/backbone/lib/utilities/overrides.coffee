@App.module "Utilities.Overrides", (Overrides, App, Backbone, Marionette, $, _) ->

  runnableEmit  = Mocha.Runnable::emit
  runnerEmit    = Mocha.Runner::emit
  uncaught      = Mocha.Runner::uncaught

  _.extend Overrides,
    restore: ->
      Mocha.Runnable::emit   = runnableEmit
      Mocha.Runner::emit     = runnerEmit
      Mocha.Runner::uncaught = uncaught

    ## still need to do should here...
    overloadMochaRunnableEmit: ->
      ## if app evironment is development we need to list to errors
      ## emitted from all Runnable inherited objects (like hooks)
      ## this makes tracking down Eclectus related App errors much easier
      Mocha.Runnable::emit = _.wrap runnableEmit, (orig, event, err) ->
        switch event
          when "error" then throw err

        orig.call(@, event, err)

    overloadMochaRunnerEmit: ->
      Mocha.Runner::emit = _.wrap runnerEmit, (orig, args...) ->
        event = args[0]

        switch event
          ## if the end event was triggered by mocha
          ## then back it up and wait for our own
          ## runner to fire the eclectus end event
          # when "end"
            # return

          ## when our runner fires this custom event
          ## then we know we're truly done and should
          ## callback the original end event
          when "cypress end"
            orig.call(@, "end")

        orig.apply(@, args)

    overloadMochaRunnerUncaught: ->
      ## if app environment isnt production we need to listen to
      ## uncaught exceptions (else it makes tracking down bugs hard)
      Mocha.Runner::uncaught = _.wrap uncaught, (orig, err) ->
        if not App.config.env("production")

          ## debugger if this isnt an AssertionError or CypressError
          ## because that means we prob f'd up something
          if not /(AssertionError|CypressError)/.test(err.name)
            console.error(err.stack)
            debugger

        orig.call(@, err)

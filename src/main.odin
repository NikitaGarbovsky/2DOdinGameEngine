package main

import "/app"
import "core:log"

// #TODO: comment this 

main :: proc() {
	context.logger = log.create_console_logger()
	app.default_context = context

	app.Init(&app.appState)
	app.Run(&app.appState)
	app.Shutdown(&app.appState)
}
package main

import "gordon"

main :: proc() {
	ctx0 := new(gordon.Context)
	ctx1 := new(gordon.Context)

	gordon.init(ctx0, "gordon-canvas-1", proc(ctx: ^gordon.Context, dt: f32) {
		ctx.is_done = true
	})
	gordon.init(
		ctx1,
		"gordon-canvas-2",
		proc(ctx: ^gordon.Context, dt: f32) {
			// ctx.is_done = true
		},
	)

}


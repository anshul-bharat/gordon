package main

import "core:fmt"
import "core:math"
import "gordon"


main :: proc() {
	ctx0 := new(gordon.Context)
	// ctx1 := new(gordon.Context)

	gordon.init(
		ctx0,
		"gordon-canvas-1",
		proc(ctx: ^gordon.Context, dt: f32) {
			// ctx.is_done = true
			ctx.curr_depth = 0
			gordon.draw_quad_vertex(
				ctx,
				{
					gordon.Vertex{pos = {10, 100, 0.0}, col = {255, 0, 0, 255}, uv = {0, 0}},
					gordon.Vertex{pos = {100, 100, 0.0}, col = {255, 255, 0, 255}, uv = {0, 0}},
					gordon.Vertex{pos = {100, 010, 0.0}, col = {0, 255, 0, 255}, uv = {0, 0}},
					gordon.Vertex{pos = {10, 10, 0.0}, col = {0, 0, 255, 255}, uv = {0, 0}},
				},
			)
			ctx.curr_depth = 1
			gordon.draw_rect(
				ctx,
				{math.mod(20 + ctx.curr_time, 3) * 10, 20},
				{50, 60},
				{255, 255, 0, 099},
			)


			gordon.draw_line(ctx, {250, 200}, {150, 200}, 19, {255, 128, 0, 255})

			gordon.draw_circle(ctx, {300, 300}, 30, {0, 255, 0, 255})
			gordon.draw_ellipse(ctx, {400, 300}, {30, 40}, {0, 255, 055, 255})

			gordon.draw_ring(ctx, {400, 400}, 30, 50, 0, math.TAU, {0, 255, 255, 255})
			gordon.draw_arc(ctx, {300, 400}, 30, 10, 0, 0.5 * math.TAU, {0, 255, 255, 255})

			gordon.draw_rect(ctx, {300, 100}, {100, 100}, {255, 0, 0, 255})
			ctx.curr_depth = 2
			gordon.draw_rect_lines(ctx, {300, 100}, {100, 100}, 50, {0, 0, 0, 200})

			gordon.draw_triangle(ctx, {
				{100, 300},
				{50, 400},
				{150, 400},
			}, {255, 0, 0, 255})

			ctx.curr_depth = 3
			gordon.draw_triangle_lines(ctx, {
					{100, 300},
					{50, 400},
					{150, 400},
				},3, {0, 0, 0, 200})
			gordon.draw_arc(ctx, {300, 300}, 30, 10, 0, 0.5 * math.TAU, {255, 255, 255, 055})
			gordon.draw_sector(ctx, {300, 300}, 30, 0.5 * math.TAU, 0.75*math.TAU, {0, 0, 0, 155})
			gordon.draw_sector_line(ctx, {300, 300}, 30, 10, 0.75 * math.TAU, math.TAU, {0, 0, 0, 155})
		},
	)

	// gordon.init(ctx1, "gordon-canvas-2", proc(ctx: ^gordon.Context, dt: f32) {
		// ctx.is_done = true
	// })

}


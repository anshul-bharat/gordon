package main

import "core:fmt"
import "gordon"


main :: proc() {
	ctx0 := new(gordon.Context)
	ctx1 := new(gordon.Context)

	gordon.init(
		ctx0,
		"gordon-canvas-1",
		proc(ctx: ^gordon.Context, dt: f32) {
			ctx.curr_depth = 1
			gordon.draw_rect(ctx, {20, 20}, {50, 60}, {255, 255, 0, 255})
			
			ctx.curr_depth = 0
			gordon.draw_quad(ctx, {
				gordon.Vertex{pos = {10, 100, 0.0}, col = {255, 0, 0, 255}, uv = {0, 0}},
				gordon.Vertex{pos = {100, 100, 0.0}, col = {255, 255, 0, 255}, uv = {0, 0}},
				gordon.Vertex{pos = {100, 10, 0.0}, col = {0, 255, 0, 255}, uv = {0, 0}},
				gordon.Vertex{pos = {10, 10, 0.0}, col = {0, 0, 255, 255}, uv = {0, 0}},
			})

		},
	)
	
	// gordon.init(ctx1, "gordon-canvas-2", proc(ctx: ^gordon.Context, dt: f32) {
	// 	ctx.is_done = true
	// })

}

// import gl "vendor:wasm/WebGL"
// main :: proc() {
	
// 	gl.CreateCurrentContextById("gordon-canvas-1", {})

// 	program, _ := gl.CreateProgramFromStrings({shader_vert}, {shader_frag})

// 	vertex_buffer := gl.CreateBuffer()
// 	gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer)

// 	gl.DeleteProgram(program)
// 	gl.DeleteBuffer(vertex_buffer)
// }
// shader_vert :: `
// precision highp float;

// attribute vec3 a_position;
// attribute vec4 a_color;
// // attribute vec2 a_uv;

// uniform mat4 u_mvp;

// varying vec4 v_color;

// void main() {
// 	v_color = a_color;
// 	gl_Position = u_mvp * vec4(a_position, 1.0);
// }
// `


// shader_frag :: `
// precision highp float;

// varying vec4 v_color;

// void main() {
// 	gl_FragColor = v_color;
// }
// `

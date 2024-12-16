package gordon

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:wasm/WebGL"

// DEFAULT_CANVAS_ID :: "gordon-canvas"


Context :: struct {
	canvas_id:  string,
	accum_time: f32,
	is_done:    bool,
	program:    gl.Program,
	buffer:     gl.Buffer,
	step:       Step_Proc,
	fini:       Fini_Proc,
	_next:      ^Context,
}

Step_Proc :: proc(ctx: ^Context, dt: f32)
Fini_Proc :: proc(ctx: ^Context)

@(private)
global_context_list: ^Context

init :: proc(ctx: ^Context, canvas_id: string, step: Step_Proc, fini: Fini_Proc = nil) -> bool {
	ctx.canvas_id = canvas_id
	gl.CreateCurrentContextById(ctx.canvas_id, {}) or_return

	if step == nil {
		return false
	}

	ctx.step = step
	ctx.program = gl.CreateProgramFromStrings({shader_vert}, {shader_frag}) or_return

	vertices := [][5]f32 {
		{+0.0, +0.5, +1.0, +0.0, +1.0},
		{+0.5, -0.5, +0.0, +1.0, +0.0},
		{-0.5, -0.5, +0.0, +0.0, +1.0},
	}

	ctx.buffer = gl.CreateBuffer()
	gl.BindBuffer(gl.ARRAY_BUFFER, ctx.buffer)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)

	ctx._next = global_context_list
	global_context_list = ctx

	return true
}

fini :: proc(ctx: ^Context) {
	if ctx.fini != nil {
		ctx->fini()
	}

	// gl.DeleteBuffer(ctx.buffer)
	// gl.DeleteProgram(ctx.program)
}

@(export)
step :: proc(dt: f32) -> bool {
	for ctx := global_context_list; ctx != nil; ctx = ctx._next {
		if ctx.is_done == true {
			p := &global_context_list
			for p^ != ctx {
				p = &p^._next
			}
			p^ = ctx._next
			fini(ctx)
			continue
		}

		ctx.accum_time += dt
		gl.SetCurrentContextById(ctx.canvas_id) or_continue
		ctx.step(ctx, dt)
		draw(ctx)
	}
	return true
}

draw :: proc(ctx: ^Context) -> bool {
	gl.SetCurrentContextById(ctx.canvas_id) or_return

	width, height := gl.DrawingBufferWidth(), gl.DrawingBufferHeight()
	aspect := f32(max(width, 1)) / f32(max(height, 1))
	gl.Viewport(0, 0, width, height)

	gl.ClearColor(0.5, 0.7, 1.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UseProgram(ctx.program)

	{
		loc := gl.GetAttribLocation(ctx.program, "a_position")
		gl.EnableVertexAttribArray(loc)
		gl.VertexAttribPointer(loc, 2, gl.FLOAT, false, size_of([5]f32), 0)
	}
	{
		loc := gl.GetAttribLocation(ctx.program, "a_color")
		gl.EnableVertexAttribArray(loc)
		gl.VertexAttribPointer(loc, 3, gl.FLOAT, false, size_of([5]f32), size_of([2]f32))
	}
	{
		mvp := glm.mat4(1)
		mvp =
			glm.mat4Perspective(glm.radians_f32(60.0), aspect, 0.1, 100.0) *
			glm.mat4LookAt({1.2, 1.2, 1.2}, {0, 0, 0}, {0, 0, 1}) *
			glm.mat4Rotate({0, 0, 1}, ctx.accum_time)
		loc := gl.GetUniformLocation(ctx.program, "u_mvp")
		gl.UniformMatrix4fv(loc, mvp)
		gl.VertexAttribPointer(loc, 3, gl.FLOAT, false, size_of([5]f32), size_of([2]f32))
	}

	gl.DrawArrays(gl.TRIANGLES, 0, 3)

	return true
}

main :: proc() {

}

shader_vert :: `
precision highp float;

attribute vec2 a_position;
attribute vec3 a_color;

uniform mat4 u_mvp;

varying vec3 v_color;

void main() {
	v_color = a_color;
	gl_Position = u_mvp * vec4(a_position, 0.0, 1.0);
}
`


shader_frag :: `
precision highp float;

varying vec3 v_color;

void main() {
	gl_FragColor = vec4(v_color, 1.0);
}
`


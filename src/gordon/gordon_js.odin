#+build js

package gordon

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:wasm/WebGL"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Color :: [4]u8

Context :: struct {
	canvas_id:     string,
	curr_time:     f32,
	is_done:       bool,
	program:       gl.Program,
	vertex_buffer: gl.Buffer,
	camera:        Camera,
	curr_depth:    f32,
	vertices:      [dynamic]Vertex,
	draw_calls:    [dynamic]Draw_Call,
	update:        Update_Proc,
	fini:          Fini_Proc,
	_next:         ^Context,
}

Update_Proc :: proc(ctx: ^Context, dt: f32)
Fini_Proc :: proc(ctx: ^Context)

Camera :: struct {
	offset:           Vec2,
	target:           Vec2,
	rotation_radians: f32,
	zoom:             f32,
	near:             f32,
	far:              f32,
}

Camera_Default :: Camera {
	zoom = 1,
	near = -1024,
	far  = 1024,
}

Vertex :: struct {
	pos: Vec3,
	col: Color,
	uv:  Vec2,
}

Draw_Call :: struct {
	program:    gl.Program,
	texture:    gl.Texture,
	offset:     int,
	length:     int,
	depth:      f32,
	depth_test: bool,
}

@(private)
global_context_list: ^Context

init :: proc(ctx: ^Context, canvas_id: string, step: Update_Proc, fini: Fini_Proc = nil) -> bool {
	ctx.canvas_id = canvas_id
	gl.CreateCurrentContextById(ctx.canvas_id, gl.DEFAULT_CONTEXT_ATTRIBUTES) or_return

	// if step == nil {
	// 	return false
	// }

	ctx.update = step
	ctx.fini = fini

	ctx.camera = Camera_Default

	gl.SetCurrentContextById(ctx.canvas_id) or_return
	ctx.program = gl.CreateProgramFromStrings({shader_vert}, {shader_frag}) or_return

	reserve(&ctx.vertices, 1 << 10)
	reserve(&ctx.draw_calls, 1 << 5)

	ctx.vertex_buffer = gl.CreateBuffer()
	gl.BindBuffer(gl.ARRAY_BUFFER, ctx.vertex_buffer)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(ctx.vertices) * size_of(ctx.vertices[0]),
		nil,
		gl.DYNAMIC_DRAW,
	)

	ctx._next = global_context_list
	global_context_list = ctx

	return true
}

fini :: proc(ctx: ^Context) {
	if ctx.fini != nil {
		ctx->fini()
	}
	gl.DeleteBuffer(ctx.vertex_buffer)
	gl.DeleteProgram(ctx.program)
}

@(export)
step :: proc(dt: f32) -> bool {
	for ctx := global_context_list; ctx != nil; ctx = ctx._next {
		ctx.curr_time += dt

		if ctx.is_done == true {
			p := &global_context_list
			for p^ != ctx {
				p = &p^._next
			}
			p^ = ctx._next
			fini(ctx)
			continue
		}

		gl.SetCurrentContextById(ctx.canvas_id) or_continue
		ctx.update(ctx, dt)
		draw_all(ctx)
	}
	return true
}

draw_all :: proc(ctx: ^Context) -> bool {
	gl.SetCurrentContextById(ctx.canvas_id) or_return

	gl.BindBuffer(gl.ARRAY_BUFFER, ctx.vertex_buffer)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(ctx.vertices) * size_of(ctx.vertices[0]),
		raw_data(ctx.vertices),
		gl.DYNAMIC_DRAW,
	)

	defer {
		clear(&ctx.vertices)
		clear(&ctx.draw_calls)
		ctx.curr_depth = 0
	}

	width, height := gl.DrawingBufferWidth(), gl.DrawingBufferHeight()
	aspect := f32(max(width, 1)) / f32(max(height, 1))

	gl.Viewport(0, 0, width, height)


	gl.ClearColor(0.5, 0.7, 1.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	
	// gl.Enable(gl.FRAMEBUFFER_SRGB); 
	// gl.Enable(gl.BLEND)
	// gl.Enable(gl.DEPTH_TEST)

	gl.UseProgram(ctx.program)

	a_pos := gl.GetAttribLocation(ctx.program, "a_pos")
	gl.EnableVertexAttribArray(a_pos)
	gl.VertexAttribPointer(a_pos, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))

	a_color := gl.GetAttribLocation(ctx.program, "a_col")
	gl.EnableVertexAttribArray(a_color)
	gl.VertexAttribPointer(
		a_color,
		4,
		gl.UNSIGNED_BYTE,
		true,
		size_of(Vertex),
		offset_of(Vertex, col),
	)

	a_uv := gl.GetAttribLocation(ctx.program, "a_uv")
	gl.EnableVertexAttribArray(a_uv)
	gl.VertexAttribPointer(a_uv, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))

	{
		// proj := glm.mat4Perspective(glm.radians_f32(60.0), aspect, 0.1, 100.0)
		proj := glm.mat4Ortho3d(0, f32(width), f32(height), 0, ctx.camera.near, ctx.camera.far)
		// proj := glm.mat4Ortho3d(-1, +1, -1, +1, -1, +1)

		origin := glm.mat4Translate({-ctx.camera.target.x, -ctx.camera.target.y, 0})
		rotation := glm.mat4Rotate({0, 0, 1}, ctx.camera.rotation_radians)
		scale := glm.mat4Scale({ctx.camera.zoom, ctx.camera.zoom, 1})
		transtation := glm.mat4Translate({ctx.camera.offset.x, ctx.camera.offset.y, 0})

		view := origin * scale * rotation * transtation
		model := glm.mat4Rotate({0, 0, 1}, ctx.curr_time)

		mvp := proj * view //* model

		gl.UniformMatrix4fv(gl.GetUniformLocation(ctx.program, "u_mvp"), mvp)
	}

	depth_loc := gl.GetUniformLocation(ctx.program, "u_depth")
	
	if len(ctx.draw_calls) > 0 {
		last := &ctx.draw_calls[len(ctx.draw_calls) - 1]

		last.length = len(ctx.vertices) - last.offset
	}

	for dc in ctx.draw_calls {
		gl.Uniform1f(depth_loc, dc.depth)

		if dc.depth_test {
			gl.Enable(gl.DEPTH_TEST)
		} else {
			gl.Disable(gl.DEPTH_TEST)
		}
		
		gl.DrawArrays(gl.TRIANGLES, dc.offset, dc.length)
	}

	return true
}

main :: proc() {

}

shader_vert :: `
precision highp float;

attribute vec3 a_pos;
attribute vec4 a_col;
attribute vec2 a_uv;

uniform mat4 u_mvp;
uniform float u_depth;

varying vec4 v_color;
varying vec2 v_uv;

void main() {
	v_color = a_col;
	v_uv = a_uv;
	gl_Position = u_mvp * vec4(a_pos, 1.0);
}
`


shader_frag :: `
precision highp float;

varying vec4 v_color;

void main() {
   
    gl_FragColor = v_color;
    
	// Assuming 'color' is the final color computed in linear space
	// vec3 gammaCorrectedColor = pow(v_color.rgb, vec3(1.0 / 2.2));
	// gl_FragColor = vec4(gammaCorrectedColor, v_color.a);
    
}
`


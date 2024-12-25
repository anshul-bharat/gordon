#+build !js

package gordon

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Color :: [4]u8

Context :: struct {
	canvas_id:     string,
	window_handle: glfw.WindowHandle,
	curr_time:     f32,
	is_done:       bool,
	program:       u32,
	vertex_buffer: u32,
	camera:        Camera,
	curr_depth:    f32,
	vertices:      [dynamic]Vertex,
	draw_calls:    [dynamic]Draw_Call,
	update:        Update_Proc,
	fini:          Fini_Proc,
	_next:         ^Context,
	_last_time:    f64,
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
	program:    u32,
	// texture:    gl.Texture,
	offset:     i32,
	length:     i32,
	depth:      f32,
	depth_test: bool,
}

@(private)
global_context_list: ^Context

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

init_window :: proc(ctx: ^Context) {
	if !bool(glfw.Init()) {
		fmt.println("GLFW has failed to load.")
		return
	}

	ctx.window_handle = glfw.CreateWindow(
		WIDTH,
		HEIGHT,
		strings.clone_to_cstring(ctx.canvas_id),
		nil,
		nil,
	)

	// terminate_window(ctx)

}

terminate_window :: proc(ctx: ^Context) {
	glfw.Terminate()
	glfw.DestroyWindow(ctx.window_handle)

	if ctx.window_handle == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}
}

init :: proc(ctx: ^Context, canvas_id: string, step: Update_Proc, fini: Fini_Proc = nil) -> bool {
	ctx.canvas_id = canvas_id

	init_window(ctx)
	defer terminate_window(ctx)

	// Load OpenGL context or the "state" of OpenGL.
	glfw.MakeContextCurrent(ctx.window_handle)

	// Load OpenGL function pointers with the specficed OpenGL major and minor version.
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	ctx.update = step
	ctx.fini = fini
	ctx.camera = Camera_Default

	// gl.SetCurrentContextById(ctx.canvas_id) or_return
	ctx.program = gl.load_shaders_source(shader_vert, shader_frag) or_return

	reserve(&ctx.vertices, 1 << 10)
	reserve(&ctx.draw_calls, 1 << 5)

	gl.GenBuffers(1, &ctx.vertex_buffer)
	gl.BindBuffer(gl.ARRAY_BUFFER, ctx.vertex_buffer)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(ctx.vertices) * size_of(ctx.vertices[0]),
		nil,
		gl.DYNAMIC_DRAW,
	)

	ctx._next = global_context_list
	global_context_list = ctx

	for ctx.is_done == false && glfw.WindowShouldClose(ctx.window_handle) == false  {
		curr_time := glfw.GetTime()

		delta := f32((curr_time - ctx._last_time))

		ctx._last_time = curr_time

		glfw.PollEvents()
		glfw.MakeContextCurrent(ctx.window_handle)

		win_step(delta)

		glfw.SwapBuffers(ctx.window_handle)
	}
	return true
}

fini :: proc(ctx: ^Context) {
	if ctx.fini != nil {
		ctx->fini()
	}
	gl.DeleteBuffers(1, &ctx.vertex_buffer)
	gl.DeleteProgram(ctx.program)
	// gl.DeleteBuffer(ctx.vertex_buffer)
	// gl.DeleteProgram(ctx.program)
	terminate_window(ctx)
}

// @(export)
win_step :: proc(dt: f32) -> bool {
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

		ctx.update(ctx, dt)
		draw_all(ctx)

		// ctx.is_done = glfw.WindowShouldClose(ctx.window_handle) == true
	}

	return true
}

draw_all :: proc(ctx: ^Context) -> bool {
	glfw.MakeContextCurrent(ctx.window_handle)

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

	width, height := glfw.GetWindowSize(ctx.window_handle)
	aspect := f32(max(width, 1)) / f32(max(height, 1))

	gl.Viewport(0, 0, width, height)

	gl.ClearColor(0.5, 0.7, 1.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	// gl.Enable(gl.FRAMEBUFFER_SRGB); 
	
	gl.UseProgram(ctx.program)

	a_pos := u32(gl.GetAttribLocation(ctx.program, "a_pos"))
	gl.EnableVertexAttribArray(a_pos)
	gl.VertexAttribPointer(a_pos, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))

	a_color := u32(gl.GetAttribLocation(ctx.program, "a_col"))
	gl.EnableVertexAttribArray(a_color)
	gl.VertexAttribPointer(
		a_color,
		4,
		gl.UNSIGNED_BYTE,
		true,
		size_of(Vertex),
		offset_of(Vertex, col),
	)

	a_uv := u32(gl.GetAttribLocation(ctx.program, "a_uv"))
	gl.EnableVertexAttribArray(a_uv)
	gl.VertexAttribPointer(a_uv, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))

	{
		//-- proj := glm.mat4Perspective(glm.radians_f32(60.0), aspect, 0.1, 100.0)
		proj := glm.mat4Ortho3d(0, f32(width), f32(height), 0, ctx.camera.near, ctx.camera.far)
		//-- proj := glm.mat4Ortho3d(-1, +1, -1, +1, -1, +1)

		origin := glm.mat4Translate({-ctx.camera.target.x, -ctx.camera.target.y, 0})
		rotation := glm.mat4Rotate({0, 0, 1}, ctx.camera.rotation_radians)
		scale := glm.mat4Scale({ctx.camera.zoom, ctx.camera.zoom, 1})
		transtation := glm.mat4Translate({ctx.camera.offset.x, ctx.camera.offset.y, 0})

		view := origin * scale * rotation * transtation
		model := glm.mat4Rotate({0, 0, 1}, ctx.curr_time)

		mvp := proj * view //* model

		u_mvp := gl.GetUniformLocation(ctx.program, "u_mvp")
		gl.UniformMatrix4fv(u_mvp, 1, false, raw_data(&mvp[0]))
	}

	depth_loc := gl.GetUniformLocation(ctx.program, "u_depth")

	if len(ctx.draw_calls) > 0 {
		last := &ctx.draw_calls[len(ctx.draw_calls) - 1]

		last.length = i32(len(ctx.vertices)) - last.offset
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


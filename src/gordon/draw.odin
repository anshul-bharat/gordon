package gordon

import "core:math"
import "core:math/linalg"

check_draw_call :: proc(ctx: ^Context) {
	if (len(ctx.draw_calls) == 0) {
		append(&ctx.draw_calls, Draw_Call{})
	}
}

draw_rect :: proc(ctx: ^Context, pos, size: Vec2, col: Color) {
	check_draw_call(ctx)

	z := ctx.curr_depth
	pos3 := Vec3{pos.x, pos.y, z}

	a, b, c, d: Vec3
	a = pos3
	b = pos3 + {size.x, 0, z}
	c = pos3 + {size.x, size.y, z}
	d = pos3 + {0, size.y, z}

	append(&ctx.vertices, Vertex{pos = a, col = col, uv = {0, 0}})
	append(&ctx.vertices, Vertex{pos = b, col = col, uv = {1, 0}})
	append(&ctx.vertices, Vertex{pos = c, col = col, uv = {1, 1}})
	
	append(&ctx.vertices, Vertex{pos = c, col = col, uv = {1, 1}})
	append(&ctx.vertices, Vertex{pos = d, col = col, uv = {0, 1}})
	append(&ctx.vertices, Vertex{pos = a, col = col, uv = {0, 0}})
}

draw_rect_lines :: proc(ctx: ^Context, pos, size: Vec2, thickness:f32, col: Color) {
	th := thickness * 0.5
	td := thickness * 0.5

	// top 
	draw_rect(ctx, pos - th, {size.x, 0} + thickness, col)
	// bottom 
	draw_rect(ctx, {pos.x, pos.y + size.y} - th, {size.x, 0} + thickness, col)
	// left 
	draw_rect(ctx, {pos.x - th, pos.y + th}, {thickness, size.y - thickness}, col)
	// right
	draw_rect(ctx, {pos.x + size.x - th, pos.y + th}, {thickness, size.y - thickness}, col)
	
	
}

draw_quad_vertex :: proc(ctx: ^Context, verts: [4]Vertex) {
	check_draw_call(ctx)

	append(&ctx.vertices, verts[0], verts[1], verts[2])
	append(&ctx.vertices, verts[2], verts[3], verts[0])
}

draw_quad :: proc(ctx: ^Context, verts: [4]Vec2, col: Color) {
	check_draw_call(ctx)

	a := Vertex {pos = {verts[0].x, verts[0].y, ctx.curr_depth}, col = col}
	b := Vertex {pos = {verts[1].x, verts[1].y, ctx.curr_depth}, col = col}
	c := Vertex {pos = {verts[2].x, verts[2].y, ctx.curr_depth}, col = col}
	d := Vertex {pos = {verts[3].x, verts[3].y, ctx.curr_depth}, col = col}

	draw_quad_vertex(ctx, {a, b, c, d})

}

draw_line :: proc(ctx: ^Context, start, end: Vec2, thickness: f32, color: Color) {
	check_draw_call(ctx)

	z := ctx.curr_depth

	dx := end - start
	dy := linalg.normalize0(Vec2{-dx.y, dx.x})

	t := dy * thickness * 0.5

	a := start + t
	b := end + t
	c := end - t
	d := start - t

	append(&ctx.vertices, Vertex{pos = {a.x, a.y, z}, col = color, uv = {0, 0}})
	append(&ctx.vertices, Vertex{pos = {b.x, b.y, z}, col = color, uv = {0, 1}})
	append(&ctx.vertices, Vertex{pos = {c.x, c.y, z}, col = color, uv = {1, 1}})


	append(&ctx.vertices, Vertex{pos = {c.x, c.y, z}, col = color, uv = {1, 1}})
	append(&ctx.vertices, Vertex{pos = {d.x, d.y, z}, col = color, uv = {1, 0}})
	append(&ctx.vertices, Vertex{pos = {a.x, a.y, z}, col = color, uv = {0, 0}})

	// draw_quad(ctx, {a, b, c, d})
}

draw_circle :: proc(ctx: ^Context, center: Vec2, radius: f32, color: Color, segments: int = 32) {
	draw_ellipse(ctx, center, {radius, radius}, color, segments)
}

draw_ellipse :: proc(ctx: ^Context, center: Vec2, radii: Vec2, color: Color, segments: int = 32) {
	check_draw_call(ctx)

	z := ctx.curr_depth

	c := Vertex {
		pos = {center.x, center.y, z},
		col = color,
	}

	for i in 0 ..<segments {
		t0 := f32(i + 0)/f32(segments) * math.TAU
		t1 := f32(i + 1)/f32(segments) * math.TAU

		a := c
		b := c
		
		a.pos.x += math.cos(t0) * radii.x
		a.pos.y += math.sin(t0) * radii.y
		
		b.pos.x += math.cos(t1) * radii.x
		b.pos.y += math.sin(t1) * radii.y

		append(&ctx.vertices, c, a, b)
	}

}

draw_ring :: proc(ctx: ^Context, center: Vec2, inner_radius, outer_radius, angle_start, angle_end: f32, color: Color, segments: int = 32) {
	check_draw_call(ctx)

	z := ctx.curr_depth

	p := Vertex {
		pos = {center.x, center.y, z},
		col = color,
	}

	for i in 0 ..<segments {
		// t0 := f32(i + 0)/f32(segments) * math.TAU
		// t1 := f32(i + 1)/f32(segments) * math.TAU

		t0 := math.lerp(angle_start, angle_end, f32(i+0) / f32(segments))
		t1 := math.lerp(angle_start, angle_end, f32(i+1) / f32(segments))

		a := p
		b := p
		c := p
		d := p
		
		a.pos.x += math.cos(t0) * outer_radius
		a.pos.y += math.sin(t0) * outer_radius
		
		b.pos.x += math.cos(t1) * outer_radius
		b.pos.y += math.sin(t1) * outer_radius

		
		c.pos.x += math.cos(t0) * inner_radius
		c.pos.y += math.sin(t0) * inner_radius
		
		d.pos.x += math.cos(t1) * inner_radius
		d.pos.y += math.sin(t1) * inner_radius

		append(&ctx.vertices, a, b, c)
		append(&ctx.vertices, b, d, c)
	}
}

draw_sector :: proc(ctx: ^Context, center: Vec2, radius, angle_start, angle_end: f32, color: Color, segments: int = 32) {
	draw_ring(ctx, center, 0, radius, angle_start, angle_end, color, segments)
}

draw_sector_line :: proc(ctx: ^Context, center: Vec2, radius, thickness, angle_start, angle_end: f32, color: Color, segments: int = 32) {
	draw_ring(ctx, center, radius - thickness*0.5, radius+thickness*0.5, angle_start, angle_end, color, segments)
}

draw_arc :: proc(ctx: ^Context, center: Vec2, radius, thickness, angle_start, angle_end: f32, color: Color, segments: int = 32) {
	draw_ring(ctx, center, radius-(thickness*0.5), radius+(thickness*0.5), angle_start, angle_end, color, segments)
}

draw_triangle :: proc(ctx: ^Context, verts: [3]Vec2, col: Color) {
	check_draw_call(ctx)

	a := Vertex {pos = {verts[0].x, verts[0].y, ctx.curr_depth}, col = col}
	b := Vertex {pos = {verts[1].x, verts[1].y, ctx.curr_depth}, col = col}
	c := Vertex {pos = {verts[2].x, verts[2].y, ctx.curr_depth}, col = col}

	append(&ctx.vertices, a, b, c)
}

draw_triangle_lines :: proc(ctx: ^Context, verts: [3]Vec2, thickness: f32, col: Color) {
	check_draw_call(ctx)

	draw_line(ctx, verts[0], verts[1], thickness, col)
	draw_line(ctx, verts[1], verts[2], thickness, col)
	draw_line(ctx, verts[2], verts[0], thickness, col)
}

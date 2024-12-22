package gordon

draw_rect :: proc(ctx: ^Context, pos, size: Vec2, col: Color) {
	if (len(ctx.draw_calls) == 0) {
		append(&ctx.draw_calls, Draw_Call{})
	}

	z := ctx.curr_depth
	pos3:= Vec3{pos.x, pos.y, z}
	
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

draw_quad :: proc(ctx: ^Context, verts: [4]Vertex) {
	if (len(ctx.draw_calls) == 0) {
		append(&ctx.draw_calls, Draw_Call{})
	}

	append(&ctx.vertices, verts[0], verts[1], verts[2])
	append(&ctx.vertices, verts[2], verts[3], verts[0])
}

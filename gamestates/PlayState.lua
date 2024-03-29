local PlayState = class( "PlayState" )

PlayState.name = "Play Screen"

function PlayState:init( manager )
	self.manager = manager
end

function PlayState:enter()
	self.game_frame = 0

	self.current_map = Map(28, 18)
	self.current_map:fill_debug()
	pathfinder:reset()

	self.pawn_list = {}
	for pawn_id = 1, 8 do
		-- place a pawn
		local spawn_x, spawn_y = self.current_map:find_random_floor()
		table.insert( self.pawn_list, {
			id = pawn_id, color = {1, pawn_id/8, 0},
			x = spawn_x, y = spawn_y,
			alive = true,
			actions = 2
		} )
		self.current_map:set_pawn( spawn_x, spawn_y, pawn_id )
	end

	self.input_state = StateManager(PlayState.input_states, "Open")
	self.selected_pawn = nil

	self.animation_queue = Queue()
	self.gun_lines = {}

	-- img.blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * TILE_SIZE, (mainmap.height + 4) * TILE_SIZE)
	-- img.blood_canvas:setFilter("linear", "nearest")

	camera.set_location( TILE_SIZE * (math.floor(self.current_map.width / 2) + 0.5), TILE_SIZE * (math.floor(self.current_map.height / 2) + 0.5) )

	mouse_sx, mouse_sy = love.mouse.getPosition()
	self.mouse_x, self.mouse_y = camera.grid_point_from_screen_point( mouse_sx, mouse_sy )
	self.mouse_fov_is_dirty = true
	self.visible_tiles = nil

	img.terrain_batches_are_dirty = true
end

function PlayState:update( dt )
	local next_state = nil

	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_sx, mouse_sy = love.mouse.getPosition()
	self.mouse_x, self.mouse_y = camera.grid_point_from_screen_point( mouse_sx, mouse_sy )

	-- updates even when paused?
	camera.update( dt )

	if not self.paused then
		if controller:pressed( 'menu' ) then
			self:pause()
			return
		end

		self.game_frame = self.game_frame + 1

		-- if self.mouse_fov_is_dirty or self.mouse_x ~= self.old_mouse_x or self.mouse_y ~= self.old_mouse_y then
		-- 	-- mouse is over a new square

		-- 	--calculate FOV
		-- 	self.visible_tiles = {}
		-- 	if self.current_map:in_bounds(self.mouse_x, self.mouse_y) and self.current_map:get_block(self.mouse_x, self.mouse_y) ~= 99 then
		-- 		self:calculate_fov(self.mouse_x, self.mouse_y, self.visible_tiles)
		-- 	else
		-- 		self.visible_tiles = nil
		-- 	end

		-- 	self.mouse_fov_is_dirty = false
		-- 	self.old_mouse_x, self.old_mouse_y = self.mouse_x, self.mouse_y
		-- end


		local next_input_state = self.input_state.state:update( self, dt )
		while next_input_state do
			self.input_state:switch_to(next_input_state)
			next_input_state = self.input_state.state:update( self, 0 )
		end

		if self.current_animation then
			if animations.process(self.current_animation, self, dt) then
				-- if true was returned, grab the next animation
				if not self.animation_queue:is_empty() then
					self.current_animation = self.animation_queue:dequeue()
				else
					self.current_animation = nil
				end
			end
		end

		-- remove dead pawns, i guess?
		for k, v in pairs( self.pawn_list ) do
			if not v.alive then
				if self.current_map:delete_pawn( v.x, v.y ) ~= k then
					error("oh my god, we've killed the wrong man")
				end
				self.pawn_list[k] = nil
			end
		end

		-- tiny.update(world, TIMESTEP)

		-- if self.gameover then
		-- 	self.manager:switch_to("GameOver")
		-- 	break
		-- end
	else
		if controller:pressed( 'menu' ) then
			self:unpause()
		end
		if controller:pressed( 'view' ) then
			next_state = "Splash"
		end
	end

	return next_state
end

function PlayState:draw()
	if self.paused then
		love.graphics.setShader( shader_desaturate )
	end

	-- love.graphics.setCanvas( game_canvas )
	love.graphics.clear( color.bg )

	self.input_state.state:draw( self )

	-- gui

	-- debug msg
	love.graphics.setColor( color.green )
	love.graphics.print( "Time: "..string.format("%.0f", self.game_frame / 60), 2, 2 )
	love.graphics.setColor( color.yellow04 )
	love.graphics.print( "I am Ozymandias, king of kings: look on my works, ye mighty, and despair", 2, window_h - 146 )
	love.graphics.setColor( color.yellow04 )
	if self.current_map:in_bounds( self.mouse_x, self.mouse_y ) then
		local block, elev = self.current_map:get_block(self.mouse_x, self.mouse_y)
		love.graphics.print( "block: "..(block or "x")..", elev: "..(elev or "x")..
			", n: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "n") or "x")..
			", w: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "w") or "x")..
			", s: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "s") or "x")..
			", e: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "e") or "x")..
			", pawn: "..(self.current_map:get_pawn(self.mouse_x, self.mouse_y, "e") or "x"), 2, window_h - 110 )
	end
	love.graphics.print( "Cursor: "..self.mouse_x..", "..self.mouse_y, 2, window_h - 74 )
	love.graphics.print( "FPS: "..love.timer.getFPS(), 2, window_h - 38 )
	love.graphics.setColor( color.white )
	love.graphics.setShader()
	if self.paused then
		-- draw pause menu
		love.graphics.setColor( color.rouge )
		love.graphics.circle( "fill", window_w/2, window_h/2, 50 )
		love.graphics.setColor( color.white )
		love.graphics.printf( "Press Q to quit", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center" )
		love.graphics.setColor( color.white )
	end

	love.graphics.draw( img.cursor, mouse_sx - 5, mouse_sy - 5 )
	-- love.graphics.setCanvas()
	-- love.graphics.draw(game_canvas)
end

function PlayState:focus( f )
	if f then
		love.mouse.setVisible( false )
		love.mouse.setGrabbed( true )
	else
		if not self.paused then
			self:pause()
		end
		love.mouse.setVisible( true )
		love.mouse.setGrabbed( false )
	end
end

function PlayState:exit()
	pathfinder:reset()
end

-- -- -- --

function PlayState:get_selected_pawn()
	local p = self.pawn_list[self.selected_pawn]
	if not p then
		error("missing pawn!")
	end
	return p, self.selected_pawn
end

function PlayState:get_next_pawn()
	for k, v in pairs( self.pawn_list ) do
		if v.actions > 0 and v.alive then
			return v
		end
	end

	error("turn over!")
end

function PlayState:enqueue_animation(o)
	o.t = 0
	if not self.current_animation then
		self.current_animation = o
	else
		self.animation_queue:enqueue(o)
	end
end

function PlayState:pause()
	self.paused = true
end

function PlayState:unpause()
	self.paused = false
end

PlayState.input_states = {
	Open = require "inputstates/OpenState",
	Selected = require "inputstates/SelectedState",
	Aiming = require "inputstates/AimingState",
}

return PlayState

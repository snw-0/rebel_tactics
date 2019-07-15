local GameOverState = class("GameOverState")

GameOverState.name = "GameOver Screen"

-- function GameOverState:enter()
-- end

function GameOverState:update(dt)
	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_x, mouse_y = love.mouse.getPosition()

	if controller:pressed('r1') or controller:pressed('view') or controller:pressed('menu') then
		gamestate_manager.switch_to("Splash")
	end
end

function GameOverState:draw()
	love.graphics.clear(color.black)

	local k = math.cos(gui_frame / 120) + 2
	love.graphics.setColor(0.1 * k, 0.03 * k, 0.2 * k, 1)
	love.graphics.circle("fill", window_w/2, window_h/2, 50)
	love.graphics.setColor(color.white)
	love.graphics.printf("rip to those that died", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center")
	love.graphics.setColor(color.white)

	love.graphics.circle("fill", mouse_x, mouse_y, 2)
end

function GameOverState:focus(f)
	if f then
		love.mouse.setVisible(false)
		love.mouse.setGrabbed(true)
	else
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
end

-- function GameOverState:exit()
-- end

return GameOverState

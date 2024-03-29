local grid = {}

function grid.hash( x, y )
	return x + y * 512
end

function grid.unhash( h )
	return h % 512, math.floor( h / 512 )
end

function grid.neighbor( x, y, dir )
	return x + dir_x[ dir ], y + dir_y[ dir ]
end

function grid.orth_dir_from_delta( dx, dy )
	if dx == 1 and dy == 0 then
		return "e"
	elseif dx == -1 and dy == 0 then
		return "w"
	elseif dx == 0 and dy == 1 then
		return "s"
	elseif dx == 0 and dy == -1 then
		return "n"
	else
		error("bad delta: "..dx..", "..dy)
	end
end

function grid.delta_from_orth_dir( dir )
	if dir == "e" then
		return 1,0
	elseif dir == "w" then
		return -1,0
	elseif dir == "s" then
		return 0,1
	elseif dir == "n" then
		return 0,-1
	else
		error("bad dir: "..dir)
	end
end

-- offsets for neighbors, cw from east
-- [6][7][8]
-- [5]   [1]
-- [4][3][2]
dir_x = { 1,  1,  0, -1, -1, -1,  0,  1 }
dir_y = { 0,  1,  1,  1,  0, -1, -1, -1 }

return grid

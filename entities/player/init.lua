local intro = require('intro') -- require intro for access to dependencies (intro.globals)
local items = require('items')
local entity = {}

function entity.new(camera)
	local player = {
		id = 'player', 
		
		dir = 0, 
		x = 0, 
		y = 0, 
		z = 0, 
		xV = 0, 
		yV = 0, 
		zV = 0, 
		
		wet = false, 
		shadow = 20, 

		animFrame = 0, 
		itemDir1 = 0, 
		itemDir2 = 0, 
		attackTimer = 10, 
		attackAnimation = {}, 
		armSway = 0, 
		attack = false,
	}
	player.camera = camera or {x=love.graphics.getWidth()/2, y=0, z=love.graphics.getHeight()/2, dir=0}

	local function p3d(p, rotation, dontProject) -- p = {x= , y= , z= } (x/z may be swapped around (?))
		rotation = rotation or player.dir -- rotation is a scalar that rotates around the y axis

		local squish = 0.5
		if dontProject then
			squish = 1
		end

		local x = math.sin(rotation)*p.x 	        + 0   +	math.sin(rotation+math.pi/2)*p.z
		local y = math.cos(rotation)*p.x*squish   + p.y +	math.cos(rotation+math.pi/2)*p.z*squish 

		local z = math.cos(rotation)*p.x 	        - p.y +	math.cos(rotation+math.pi/2)*p.z -- z is used for depth sorting

		return x,y,z
	end

	player.attackAnimation = {
		{0, 0, 0, 0}, -- {attackTimer, itemDir1, itemDir2, armSway}
		{0.05, -math.pi/3, math.pi/3, -math.pi/2},
		{0.2, math.pi/3, 0, math.pi/2},
		{0.4, 0, 0, 0},
		damage = false
	}

	local function attackAnimationKey()
		for i=1, #player.attackAnimation do
			if player.attackAnimation[i][1] > player.attackTimer then
				return i-1
			end
		end
		return #player.attackAnimation
	end

	player.inventory = require('entities.player.inventory')
	player.inventory.vertices = function() -- generates the vertices for a mesh to contain the item image
		local img = (player.inventory[player.inventory.selected][1] and items[player.inventory[player.inventory.selected][1]].img) or false
		local itemType = (player.inventory[player.inventory.selected][1] and items[player.inventory[player.inventory.selected][1]].type) or false
		if not img then 
			return {{-0,-0, 0,0},{0,-0, 1,0},{0,0, 1,1},{-0,0, 0,1}}
		end

		if itemType == "sword" then
			tlx, tly = 0,-img:getHeight()/2
			trx, try = img:getWidth(),-img:getHeight()/2
			brx, bry = img:getWidth(), img:getHeight()/2
			blx, bly = 0, img:getHeight()/2
		else
			tlx, tly = -img:getHeight()/4,-img:getHeight()/4
			trx, try = img:getWidth()/4,-img:getHeight()/4
			brx, bry = img:getWidth()/4, img:getHeight()/4
			blx, bly = -img:getHeight()/4, img:getHeight()/4
		end

		player.itemDir2 = player.itemDir2+ (player.attackAnimation[attackAnimationKey()][3]-player.itemDir2)*0.5
		local dir = 0
		if itemType == "sword" then
			dir = math.sin(player.animFrame)*math.pi/4+math.pi/4*math.sqrt(player.xV^2+player.yV^2)/8.57
		end
		tlx, tly = p3d({x=tly, y=0, z=tlx}, dir+ player.itemDir2, 0)
		trx, try = p3d({x=try, y=0, z=trx}, dir+ player.itemDir2, 0)
		brx, bry = p3d({x=bry, y=0, z=brx}, dir+ player.itemDir2, 0)
		blx, bly = p3d({x=bly, y=0, z=blx}, dir+ player.itemDir2, 0)

		player.itemDir1 = player.itemDir1+ (player.attackAnimation[attackAnimationKey()][2]-player.itemDir1)*0.5
		dir = player.dir+player.itemDir1
		tlx, tly = p3d({x=tlx, y=tly, z=0}, dir)
		trx, try = p3d({x=trx, y=try, z=0}, dir)
		brx, bry = p3d({x=brx, y=bry, z=0}, dir)
		blx, bly = p3d({x=blx, y=bly, z=0}, dir)

		return {{tlx, tly, 0,0},{trx, try, 1,0},{brx, bry, 1,1},{blx, bly, 0,1}}
	end
	player.inventory.mesh = love.graphics.newMesh(player.inventory.vertices(), "fan", "stream")
	if player.inventory[player.inventory.selected][1] then -- if the selected item isnt pointing to an empty table
		player.inventory.mesh:setTexture(items[player.inventory[player.inventory.selected][1]].img)
	end

	local x,y,z, x1,y1,z1 = 0,0,0, 0,0,0 -- creates the local variables, outputs dont get used
	player.objects = { -- table of every body part in the player (automatically gets sorted by z each frame)
		{
			id='legs',
			z=1,
			draw = function(self)
				love.graphics.setColour(0.8*0.8,0.6*0.8,0.3*0.8)
				if not player.wet then
					love.graphics.setLineWidth(8)
					x,y,z = p3d({x=0, y=-12, z=6})
					x1,y1,z1 = p3d({x=math.sin(math.sin(player.animFrame)*math.pi/2-player.armSway/2)*12, y=-12+math.cos(math.sin(player.animFrame)*math.pi/2-player.armSway/2)*12, z=6})
					love.graphics.line(x, y, x1, y1) -- left leg
					love.graphics.ellipse('fill', x1, y1, 5, 2.5)
					x,y,z = p3d({x=0, y=-12, z=-6})
					x1,y1,z1 = p3d({x=math.sin(-math.sin(player.animFrame)*math.pi/2+player.armSway/2)*12, y=-12+math.cos(math.sin(player.animFrame)*math.pi/2+player.armSway/2)*12, z=-6})
					love.graphics.line(x, y, x1, y1)
					love.graphics.ellipse('fill', x1, y1, 5, 2.5)
				end

				_, _, self.z = p3d({x=0, y=-12, z=0})
			end 
		},
		{
			id='left arm',
			z=2,
			draw = function(self)
				love.graphics.setColour(0.3*0.9,0.6*0.9,0.8*0.9)
				x,y,z = p3d({x=0, y=-24, z=20})
				local dir = -math.sin(player.animFrame)*math.pi/2
				if player.attackTimer < player.attackAnimation[#player.attackAnimation][1] then
					dir = -player.armSway
				end
				x1,y1 = p3d({x=math.sin(dir)*12, y=-24+math.cos(math.sin(dir))*12, z=20})

				love.graphics.setLineWidth(10)
				love.graphics.line(x, y, x1, y1)

				love.graphics.circle('fill', x, y, 5)
				love.graphics.setColour(0.9,0.7,0.6)
				love.graphics.circle('fill', x1, y1, 5)

				_, _, self.z = p3d({x=0, y=-24, z=20})
			end 
		},
		{
			id='right arm',
			z=3,
			draw = function(self)
				love.graphics.setColour(0.3*0.9,0.6*0.9,0.8*0.9)
				x,y,z = p3d({x=0, y=-24, z=-20})
				local dir = math.sin(player.animFrame)*math.pi/2
				if player.attackTimer < player.attackAnimation[#player.attackAnimation][1] then
					dir = player.armSway
				end
				x1,y1 = p3d({x=math.sin(dir)*12, y=-24+math.cos(math.sin(dir))*12, z=-20})
				
				love.graphics.setLineWidth(10)
				love.graphics.line(x, y, x1, y1)

				love.graphics.circle('fill', x, y, 5)
				love.graphics.setColour(0.9,0.7,0.6)
				love.graphics.circle('fill', x1, y1, 5)

				_, _, self.z = p3d({x=0, y=-24, z=-20})
			end 
		},
		{
			id='body',
			z=4,
			vertices = function(self, point, perspective)
				local perspective = perspective or 0
				local vertices = {}
				table.insert(vertices, {0, 0, 0.5, 0.5})

				for i=0, 30 do
					local angle = (i / 30)*math.pi*2

					local x = math.cos(angle)
					local y = math.sin(angle)

					local multiply = 19/20
					if y > point then
						multiply = math.sqrt(1^2 - point^2)
						x = x* multiply
						y = y* multiply* perspective +point
						
						local len = math.sqrt(x^2 + y^2)
						if len > 1 then
							x = x / len
							y = y / len
						end
					end

					table.insert(vertices, {x*20, y*20})
				end
				return vertices
			end,
			draw = function(self)
				love.graphics.setColour(0.3,0.6,0.8)
				if player.wet then
					if not self.mesh then
						self.mesh = love.graphics.newMesh(self:vertices(math.max(0, -1), 0.5), "fan", "stream")
					else
						local vertices = self:vertices(math.max(0, -1), 0.5)
						self.mesh:setVertices(vertices, 1, #vertices)
					end
					love.graphics.draw(self.mesh, 0, -24)
				else
					love.graphics.ellipse("fill", 0, -24, 20, 19)
				end

				_, _, self.z = p3d({x=0, y=-24, z=0})
			end 
		},
		{
			id='left eye',
			z=5,
			draw = function(self)
				love.graphics.setColour(0.13,0.13,0.13)
				x,y,z = p3d({x=16, y=-44, z=0}, (player.dir)+14/180*math.pi)
				love.graphics.ellipse("fill", x, y, 2.5, 5)

				_, _, self.z = p3d({x=16, y=-44, z=0}, (player.dir)+14/180*math.pi)
			end 
		},
		{
			id='right eye',
			z=6,
			draw = function(self)
				love.graphics.setColour(0.13,0.13,0.13)
				x,y,z = p3d({x=16, y=-44, z=0}, (player.dir)-14/180*math.pi)
				love.graphics.ellipse("fill", x, y, 2.5, 5)

				_, _, self.z = p3d({x=16, y=-44, z=0}, (player.dir)-14/180*math.pi)
			end 
		},
		{
			id='head',
			z=7,
			draw = function(self)
				love.graphics.setColour(0.9,0.7,0.6)
				love.graphics.ellipse("fill", 0, -44, 20/1.2, 19/1.2)

				self.z = 44
			end 
		},
		{
			id='item',
			z=8,
			draw = function(self)
				local dir = math.sin(player.animFrame)*math.pi/2
				if player.attackTimer < player.attackAnimation[#player.attackAnimation][1] then
					dir = player.armSway
				end
				x,y = p3d({x=math.sin(dir)*12, y=-24+math.cos(math.sin(dir))*12, z=-20})
				--local itemType = (player.inventory[player.inventory.selected][1] and items[player.inventory[player.inventory.selected][1]].type) or false
				love.graphics.setColour(1,1,1)
				love.graphics.draw(player.inventory.mesh, x, y, nil, 0.5, nil, 0)
				player.inventory.mesh:setVertices(player.inventory.vertices())

				local height = -70
				local cos = math.cos(player.dir+math.pi/2+player.itemDir1)
				-- if (player.dir+math.pi/2+player.itemDir1) > math.pi/2*3  then--or (player.dir+math.pi/2+math.pi/4) <  -math.pi/2*3
				--   height = -5
				-- end
				if cos>0 then
					height = -5
				end

				_, _, self.z = p3d({x=0, y=height, z=-20})
			end 
		},
	}

	function player:update(dt)
		txb, tyb = p3d({z = self.camera.x+self.camera.screenShake.x, y=0, x=self.camera.z+self.camera.screenShake.y/2}, self.camera.dir)
		tx, ty = p3d({z=self.x, y=0, x=self.z}, self.camera.dir)
		tx = tx + txb + love.graphics.getWidth()/2
		ty = ty + tyb + love.graphics.getHeight()/2
		self.dir = math.atan2((tx-love.mouse.getX()), (ty-love.mouse.getY())*2)+math.pi + player.armSway/4

		self.attackTimer = self.attackTimer + dt
		local itemType = (self.inventory[self.inventory.selected][1] and items[self.inventory[self.inventory.selected][1]].type) or false
		if attackAnimationKey() == 3 and self.attackAnimation.damage and itemType == "sword" then
			self.camera.screenShake.xV = self.camera.screenShake.xV + math.sin(self.dir)*-5
			self.camera.screenShake.yV = self.camera.screenShake.yV + math.cos(self.dir)*-5

			self.attack = true
			self.attackAnimation.damage = false
		end
		self.armSway = self.armSway+ (self.attackAnimation[attackAnimationKey()][4]-self.armSway)*0.5

		player.inventory:update()

		if love.keyboard.isDown("r") then
			self.x = 0
			self.y = 0
			self.z = 0
		end

		if love.mouse.isDown(1) and not player.inventory.open then
			if player.attackTimer > 0.5 and itemType ~= "material" then
				player.attackTimer = 0
				player.attackAnimation.damage = true
			end
		end

		local acceleration = 2
		local moved = false
		if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
			--self.xV = self.xV - acceleration*60*dt
			self.xV = self.xV - math.cos(self.camera.dir)*acceleration*60*dt
			self.zV = self.zV - math.sin(self.camera.dir)*acceleration*60*dt
			moved = true
		end
		if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
			--self.xV = self.xV + acceleration*60*dt
			self.xV = self.xV + math.cos(self.camera.dir)*acceleration*60*dt
			self.zV = self.zV + math.sin(self.camera.dir)*acceleration*60*dt
			moved = true
		end
		if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
			--self.zV = self.zV - acceleration*60*dt
			self.xV = self.xV - math.cos(self.camera.dir+math.pi/2)*acceleration*60*dt
			self.zV = self.zV - math.sin(self.camera.dir+math.pi/2)*acceleration*60*dt
			moved = true
		end
		if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
			--self.zV = self.zV + acceleration*60*dt
			self.xV = self.xV + math.cos(self.camera.dir+math.pi/2)*acceleration*60*dt
			self.zV = self.zV + math.sin(self.camera.dir+math.pi/2)*acceleration*60*dt
			moved = true
		end
		
		-- local damping = 0.81
		-- if self.wet < 0 then
		--   damping = 0.7
		-- end
		local vLength = math.sqrt(self.xV^2 + self.zV^2) -- length of the x/z velocity
		--local maxSpeed = (acceleration / (1 - damping)) - acceleration -- calculates terminal velocity given acceleration and damping
		--local multiplier = maxSpeed/math.max(maxSpeed, vLength) -- normalises the speed at which the player can move
		self.xV, 
		self.zV = -- *damping*multiplier
		self.xV * (1 / (1 + (dt * 14))),--* damping*multiplier, 
		self.zV * (1 / (1 + (dt * 14)))--* damping*multiplier

		if vLength > 8.57 then
			player.xV = player.xV/vLength*8.57
			player.zV = player.zV/vLength*8.57
		end

		self.x, 
		self.z = -- +Velocity
		self.x + self.xV*60*dt,
		self.z + self.zV*60*dt

		local fall = 0.3
		if self.wet then
			fall = 0.1
		end
		self.animFrame = (moved and (self.animFrame + 8.57/50*60*dt)) or (self.animFrame % math.pi + (0-self.animFrame % math.pi)*60*dt *(1 / (1 + (dt*60*1/ fall))))
		self.y = -math.abs(math.sin(self.animFrame)*math.pi/2*10)
	end

	function player:draw()
		local tx, ty = p3d({x=self.z, y=self.y, z=self.x}, self.camera.dir)
		tx = tx+math.sin(self.dir)*self.armSway*-5 		 --+ self.camera.x
		ty = ty+math.cos(self.dir)*self.armSway*0.5*-5 --+ self.camera.y
		love.graphics.translate(tx, ty)

		table.sort(self.objects, function(a,b) 
			return (a.z < b.z)
		end)
		for i=1, #self.objects do
			self.objects[i]:draw()
		end

		if love.keyboard.isDown('`') then
			love.graphics.setLineWidth(2)

			love.graphics.setColour(1,0,0)
			x, y = p3d({x=40, y=0, z=0})
			love.graphics.line(0,0, x,y)

			love.graphics.setColour(0,1,0)
			x, y = p3d({x=0, y=-40, z=0})
			love.graphics.line(0,0, x,y)

			love.graphics.setColour(0,0,1)
			x, y = p3d({x=0, y=0, z=40})
			love.graphics.line(0,0, x,y)

			love.graphics.setColour(0,0,0)
			love.graphics.print(self.dir)
		end
		
		--love.graphics.setColour(0,0,0)
		--local vLength = math.sqrt(self.xV^2 + self.zV^2)
		--love.graphics.print(vLength)
		
		love.graphics.translate(-tx, -ty)
	end

	local function distance(x1,y1, x2,y2)
		return math.sqrt((y2-y1)^2 + (x2-x1)^2)
	end

	local function angleDifference(a, b)
		local difference = (a - b + math.pi) % (math.pi * 2) - math.pi
		return (difference < -math.pi) and (difference + math.pi * 2) or difference
	end

	function player:damage(x, z, plrdir)
		local dist = distance(x,z, self.x,self.z)
		if dist < 100 and dist > 1 then
			local dir = math.atan2(self.x-x, self.z-z)
			if math.abs(angleDifference(dir, plrdir)) < math.pi/2 then
				self.xV = self.xV + 15 * (self.x-x)/dist
				self.zV = self.zV + 15 * (self.z-z)/dist
			end
		end
	end

	function player:keypressed(k)
		player.inventory:keypressed(k)
	end

	function love.wheelmoved(x,y)
		player.inventory:wheelmoved(x,y)
	end

	function love.mousepressed(x,y,b)
		player.inventory:mousepressed(x,y,b)
	end

	return player
end
return entity
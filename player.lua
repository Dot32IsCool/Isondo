local intro = require('intro') -- require intro for access to dependencies (intro.globals)
local items = require('items')
local entity = {}

function entity.new(camera)
  local player = {id = 'player', dir = 0, x = 0, y = 0, z = 0, xV = 0, yV = 0, zV = 0, animFrame = 0, wet = -0, shadow = 20}
  player.camera = camera or {love.graphics.getWidth()/2, love.graphics.getHeight()/2}

  local function p3d(p, rotation) -- p = {x= , y= , z= } (x/z may be swapped around (?))
    rotation = rotation or player.dir -- rotation is a scalar that rotates around the y axis

    local x = math.sin(rotation)*p.x 	 + 0   +	math.sin(rotation+math.pi/2)*p.z
    local y = math.cos(rotation)*p.x/2 + p.y +	math.cos(rotation+math.pi/2)*p.z/2

    local z = math.cos(rotation)*p.x 	 - p.y +	math.cos(rotation+math.pi/2)*p.z -- z is used for depth sorting

    return x,y,z
  end

  player.inventory = {
    selected = 1,
    vertices = function() -- generates the vertices for a mesh to contain the item image
      local img = (player.inventory[player.inventory.selected][1] and items[player.inventory[player.inventory.selected][1]].img) or false
      if not img then 
        return {{-0,-0, 0,0},{0,-0, 1,0},{0,0, 1,1},{-0,0, 0,1}}
      end

      tlx, tly, tlz = 0,-img:getHeight()/2, 0
      trx, try, trz = img:getWidth(),-img:getHeight()/2, 0
      brx, bry, brz = img:getWidth(), img:getHeight()/2, 0
      blx, bly, blz = 0, img:getHeight()/2, 0

      tlx, tly, tlz = p3d({x=tlx, y=tly, z=tlz})
      trx, try, trz = p3d({x=trx, y=try, z=trz})
      brx, bry, brz = p3d({x=brx, y=bry, z=brz})
      blx, bly, blz = p3d({x=blx, y=bly, z=blz})

      return {{tlx, tly, 0,0},{trx, try, 1,0},{brx, bry, 1,1},{blx, bly, 0,1}}
    end,
  }

  player.inventory[1] = {1} -- "{1}" is the index to an item in the items table
  for i=1, 10-#player.inventory do -- ensures 10 items
    table.insert(player.inventory, {}) -- insert empty table
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
        if player.wet < 0 then
          love.graphics.setColour(0.8*0.8*intro.globals.water.r, 0.6*0.8*intro.globals.water.g, 0.3*0.8*intro.globals.water.b)
        end
        love.graphics.setLineWidth(8)
        x,y,z = p3d({x=0, y=-12, z=6})
        x1,y1,z1 = p3d({x=math.sin(math.sin(player.animFrame)*math.pi/2)*12, y=-12+math.cos(math.sin(player.animFrame)*math.pi/2)*12, z=6})
        love.graphics.line(x, y, x1, y1) -- left leg
        x,y,z = p3d({x=0, y=-12, z=-6})
        x1,y1,z1 = p3d({x=math.sin(-math.sin(player.animFrame)*math.pi/2)*12, y=-12+math.cos(math.sin(player.animFrame)*math.pi/2)*12, z=-6})
        love.graphics.line(x, y, x1, y1)

        _, _, self.z = p3d({x=0, y=-12, z=0})
      end 
    },
    {
      id='left arm',
      z=2,
      draw = function(self)
        love.graphics.setColour(0.3*0.9,0.6*0.9,0.8*0.9)
        if player.wet < -23 then
          love.graphics.setColour(0.3*0.9*intro.globals.water.r, 0.6*0.9*intro.globals.water.g, 0.8*0.9*intro.globals.water.b)
        end
        x,y,z = p3d({x=0, y=-24, z=20})
        x1,y1 = p3d({x=math.sin(-math.sin(player.animFrame)*math.pi/2)*12, y=-24+math.cos(math.sin(player.animFrame)*math.pi/2)*12, z=20})
        love.graphics.line(x, y, x1, y1)

        _, _, self.z = p3d({x=0, y=-24, z=20})
      end 
    },
    {
      id='right arm',
      z=3,
      draw = function(self)
        love.graphics.setColour(0.3*0.9,0.6*0.9,0.8*0.9)
        if player.wet < -23 then
          love.graphics.setColour(0.3*0.9*intro.globals.water.r, 0.6*0.9*intro.globals.water.g, 0.8*0.9*intro.globals.water.b)
        end
        x,y,z = p3d({x=0, y=-24, z=-20})
        x1,y1 = p3d({x=math.sin(math.sin(player.animFrame)*math.pi/2)*12, y=-24+math.cos(math.sin(player.animFrame)*math.pi/2)*12, z=-20})
        love.graphics.line(x, y, x1, y1)

        love.graphics.setColour(1,1,1)
        --love.graphics.draw(items[player.inventory[1][1][1]].img, x1, y1, nil, 0.5, nil, 0, items[player.inventory[1][1][1]].img:getHeight()/2)
        love.graphics.draw(player.inventory.mesh, x1, y1, nil, 0.5, nil, 0)
        player.inventory.mesh:setVertices(player.inventory.vertices())

        _, _, self.z = p3d({x=0, y=-24, z=-20})
      end 
    },
    {
      id='body',
      z=4,
      vertices = function(self, point)
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
            y = y* multiply* 0.5 +point
            
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
        local wet = false
        if player.wet < -24+19 then -- hieght from player to ground minus radious of body
          wet = true
        end

        love.graphics.setColour(0.3,0.6,0.8)
        if wet then
          love.graphics.setColour(0.3*intro.globals.water.r, 0.6*intro.globals.water.g, 0.8*intro.globals.water.b)
        end
        love.graphics.ellipse("fill", 0, -24, 20, 19)

        if wet then 
          local normWet = (player.wet+24)/19
          if not self.mesh then
            self.mesh = love.graphics.newMesh(self:vertices(math.max(normWet, -1)), "fan", "stream")
          else
            local vertices = self:vertices(math.max(normWet, -1))
            self.mesh:setVertices(vertices, 1, #vertices)
          end
          love.graphics.setColour(0.3,0.6,0.8)
          love.graphics.draw(self.mesh, 0, -24)
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

        _, _, self.z = p3d({x=0, y=-44, z=0})
      end 
    }
  }

  function player:draw()
    local tx, ty = p3d({x=self.z, y=self.y, z=self.x}, self.camera.r)
  	love.graphics.translate(tx, ty)

    table.sort(self.objects, function(a,b) 
      return (a.z < b.z)
    end)
    for i=1, #self.objects do
      self.objects[i]:draw()
    end
    
    --love.graphics.setColour(0,0,0)
    --local vLength = math.sqrt(self.xV^2 + self.zV^2)
    --love.graphics.print(vLength)
    
    love.graphics.translate(-tx, -ty)
  end

  function player:update(dt)
    local tx, ty = p3d({z=self.x, y=0, x=self.z}, self.camera.r)
    tx = tx + self.camera.x
    ty = ty + self.camera.z
    self.dir = math.atan2((tx-love.mouse.getX()), (ty-love.mouse.getY())*2)+math.pi

    if love.keyboard.isDown("r") then
      self.x = 0
      self.y = 0
      self.z = 0
    end

    local acceleration = 2
    local moved = false
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
      --self.xV = self.xV - acceleration*60*dt
      self.xV = self.xV - math.cos(self.camera.r)*acceleration*60*dt
      self.zV = self.zV - math.sin(self.camera.r)*acceleration*60*dt
      moved = true
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
      --self.xV = self.xV + acceleration*60*dt
      self.xV = self.xV + math.cos(self.camera.r)*acceleration*60*dt
      self.zV = self.zV + math.sin(self.camera.r)*acceleration*60*dt
      moved = true
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
      --self.zV = self.zV - acceleration*60*dt
      self.xV = self.xV - math.cos(self.camera.r+math.pi/2)*acceleration*60*dt
      self.zV = self.zV - math.sin(self.camera.r+math.pi/2)*acceleration*60*dt
      moved = true
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
      --self.zV = self.zV + acceleration*60*dt
      self.xV = self.xV + math.cos(self.camera.r+math.pi/2)*acceleration*60*dt
      self.zV = self.zV + math.sin(self.camera.r+math.pi/2)*acceleration*60*dt
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
    if self.wet < 0 then
      fall = 0.1
    end
    self.animFrame = (moved and (self.animFrame + 8.57/50*60*dt)) or (self.animFrame % math.pi + (0-self.animFrame % math.pi)*fall)
    self.y = -math.abs(math.sin(self.animFrame)*math.pi/2*10)
    self.wet = -0-self.y
  end

  return player
end
return entity
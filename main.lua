local intro = require("intro")

local camera = {x=love.graphics.getWidth()/2, y=0, z=love.graphics.getHeight()/2, r=0}
local direction = 0

local player = require("player")
local tree = require("tree")
local entities = {}
table.insert(entities, player.new(camera))
for i=1, 30 do
  table.insert(entities, tree.new(camera, love.math.random(-800, 800), love.math.random(-800, 800)))
end

local sword = love.graphics.newImage('items/sword.png')

--local tree = tree.new()
local shadowMap = love.graphics.newCanvas()

local function pprint(stringg, x, y)
  local r,g,b,a = love.graphics.getColour() 
  if type(stringg) == "number" then
    stringg = math.floor(stringg*10)/10
  end
  love.graphics.setColour(0,0,0)
  love.graphics.print(stringg, x, y)
  love.graphics.setColour(r,g,b,a)
end

local function p3d(p, rotation)
    rotation = rotation or player.dir -- rotation is a scalar that rotates around the y axis

    local x = math.sin(rotation)*p.x   + 0   +  math.sin(rotation+math.pi/2)*p.z
    local y = math.cos(rotation)*p.x/2 + p.y +  math.cos(rotation+math.pi/2)*p.z/2

    local z = math.cos(rotation)*p.x   - p.y +  math.cos(rotation+math.pi/2)*p.z

    return x,y,z --it is possible that i have messed up the x/z directions ¯\_(ツ)_/¯
  end

function love.load()
  intro:init()
  --love.graphics.setBackgroundColour(142/255*intro.globals.water.r,183/255*intro.globals.water.g,130/255*intro.globals.water.b)
  love.graphics.setBackgroundColour(142/255,183/255,130/255)
end

function love.update(dt)
	intro:update(dt)

  for i=1, #entities do
    entities[i]:update(dt)
  end

  camera.r = camera.r + (direction*math.pi/2 - camera.r)*60*dt *(1 / (1 + (dt*60*1/ 0.2)))

  -- if love.keyboard.isDown('e') then
  --   camera.r = camera.r - 0.05
  -- end
  -- if love.keyboard.isDown('q') then
  --   camera.r = camera.r + 0.05
  -- end
end

function love.draw()
  do love.graphics.setCanvas(shadowMap)
    love.graphics.clear()
    love.graphics.setColour(0,0.2,0.1,1)

    love.graphics.ellipse("fill", love.mouse.getX(), love.mouse.getY(), 20, 10)

    love.graphics.translate(camera.x, camera.z)-- Camera +

    love.graphics.setColour(0,0.2,0.1,1)
    for i=1, #entities do
      local tx, ty = p3d({x=entities[i].z, y=entities[i].y, z=entities[i].x}, camera.r)
      love.graphics.translate(tx, ty)
      love.graphics.ellipse("fill", 0, 0, entities[i].shadow, entities[i].shadow/2)
      love.graphics.translate(-tx, -ty)
    end
  end
  love.graphics.setCanvas()
  love.graphics.setColour(1,1,1,0.1)
  love.graphics.draw(shadowMap, -camera.x, -camera.z)

  table.sort(entities, function(a,b)
    local _, _, az = p3d({x=a.z, y=0, z=a.x}, camera.r)
    local _, _, bz = p3d({x=b.z, y=0, z=b.x}, camera.r)
    return (az < bz)
  end)
  for i=1, #entities do
    entities[i]:draw()
  end

  love.graphics.setColour(1,1,1)
  ----love.graphics.polygon('fill',0,0, 5,-5, 10,-5, 10,-10, 15,-15, 20,-10, 20,-5, 50,-5, 55,0, 50,5, 20,5, 20,10, 15,15, 10,10, 10,5, 5,5)
  --love.graphics.polygon('fill', 0,0, 5,-5, 50,-5, 55,0, 50,5, 5,5)
  --love.graphics.polygon('fill', 15,-15, 20,-10, 20,10, 15,15, 10,10, 10,-10)
  --love.graphics.draw(sword, entities[1].x, entities[1].y, nil, 0.5)

  love.graphics.translate(-camera.x, -camera.z)-- Camera -
  local f = love.graphics.getFont()

  do local compass = {size=30, x=love.graphics.getWidth()-80, y=love.graphics.getHeight()-80}
    love.graphics.setLineWidth(2)
    love.graphics.setColour(1,1,1, 0.3)
    love.graphics.circle('line', compass.x, compass.y, compass.size)
    love.graphics.setColour(1,1,1)
    love.graphics.circle('fill', compass.x, compass.y, 3)
    love.graphics.line(compass.x, compass.y-compass.size/3, compass.x, compass.y+compass.size/3)

    love.graphics.print('N', compass.x + math.cos(-camera.r-math.pi/2)*compass.size-f:getWidth('N')/2, compass.y + math.sin(-camera.r-math.pi/2)*compass.size-f:getHeight()/2)
    love.graphics.print('E', compass.x + math.cos(-camera.r)*compass.size-f:getWidth('E')/2, compass.y + math.sin(-camera.r)*compass.size-f:getHeight()/2)
    love.graphics.print('S', compass.x + math.cos(-camera.r+math.pi/2)*compass.size-f:getWidth('S')/2, compass.y + math.sin(-camera.r+math.pi/2)*compass.size-f:getHeight()/2)
    love.graphics.print('W', compass.x + math.cos(-camera.r-math.pi)*compass.size-f:getWidth('W')/2, compass.y + math.sin(-camera.r-math.pi)*compass.size-f:getHeight()/2)
  end

  pprint(camera.x)
  pprint(camera.z, 0, 20)
  --pprint(tree.x)

  intro:draw()
end

function love.resize()
  camera.x = love.graphics.getWidth()/2
  camera.z = love.graphics.getHeight()/2
  shadowMap = love.graphics.newCanvas()
end

function love.keypressed(k)
  if k == 'e' then
    direction = direction - 1
  end
  if k == 'q' then
    direction = direction + 1
  end
end
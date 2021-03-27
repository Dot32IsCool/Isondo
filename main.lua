local player = {dir = 0}
local camera = {x=love.graphics.getWidth()/2, y=love.graphics.getHeight()/2}

function love.load()
  require("Intro")
  introInitialise("Games")

  screen = {}
  screen.font = love.graphics.newFont("Public_Sans/static/PublicSans-Black.ttf", 20)

  --[[Creates Australian-English translations of the colour functions]]
  love.graphics.getBackgroundColour = love.graphics.getBackgroundColor
  love.graphics.getColour           = love.graphics.getColor
  love.graphics.getColourMask       = love.graphics.getColorMask
  love.graphics.getColourMode       = love.graphics.getColorMode
  love.graphics.setBackgroundColour = love.graphics.setBackgroundColor
  love.graphics.setColour           = love.graphics.setColor
  love.graphics.setColourMask       = love.graphics.setColorMask
  love.graphics.setColourMode       = love.graphics.setColorMode

  love.graphics.setBackgroundColour(142/255,183/255,130/255)
end

function love.update(dt)
	introUpdate(dt)
  player.dir = math.atan2((love.mouse.getX()-camera.x), (love.mouse.getY()-camera.y)*2)
end

function love.draw()
  love.graphics.setColour(0,0.2,0.1,0.3)--cursor
  love.graphics.ellipse("fill", love.mouse.getX(), love.mouse.getY(), 20, 10)

  love.graphics.translate(camera.x, camera.y)

  love.graphics.setColour(0.8*0.8,0.6*0.8,0.3*0.8)--pants 
  love.graphics.rectangle("fill", math.sin((player.dir)+math.pi/2)*6-4, math.cos((player.dir)+math.pi/2)*6/2+12, 8, 12)
  love.graphics.rectangle("fill", math.sin((player.dir)-math.pi/2)*6-4, math.cos((player.dir)-math.pi/2)*6/2+12, 8, 12)

  love.graphics.setColour(0.3*0.9,0.6*0.9,0.8*0.9)--arm
  love.graphics.rectangle("fill", math.sin((player.dir % math.pi)+math.pi/2)*20-4, math.cos((player.dir % math.pi)+math.pi/2)*20/2, 8, 12)
 
  love.graphics.setColour(0.3,0.6,0.8)--body
  love.graphics.ellipse("fill", 0, 0, 20, 19)

  love.graphics.setColour(0.3*0.9,0.6*0.9,0.8*0.9)--arm
  love.graphics.rectangle("fill", math.sin((player.dir % math.pi)-math.pi/2)*20-4, math.cos((player.dir % math.pi)-math.pi/2)*20/2, 8, 12)

  love.graphics.setColour(0,0,0)--eyes
  love.graphics.ellipse("fill", math.sin((player.dir)-14/180*math.pi)*16, math.cos((player.dir)-14/180*math.pi)*16/2-20, 2.5, 5)
  love.graphics.ellipse("fill", math.sin((player.dir)+14/180*math.pi)*16, math.cos((player.dir)+14/180*math.pi)*16/2-20, 2.5, 5)

  love.graphics.setColour(0.9,0.7,0.6)--head
  love.graphics.ellipse("fill", 0, 0-20, 20/1.2, 19/1.2)

  love.graphics.setColour(0,0,0)--eyes
  if player.dir-14/180*math.pi < math.pi/2 and player.dir-14/180*math.pi > -math.pi/2 then
    love.graphics.ellipse("fill", math.sin((player.dir)-14/180*math.pi)*16, math.cos((player.dir)-14/180*math.pi)*16/2-20, 2.5, 5)
  end
  if player.dir+14/180*math.pi < math.pi/2 and player.dir+14/180*math.pi > -math.pi/2 then
    love.graphics.ellipse("fill", math.sin((player.dir)+14/180*math.pi)*16, math.cos((player.dir)+14/180*math.pi)*16/2-20, 2.5, 5)
  end
  
  love.graphics.translate(-camera.x, -camera.y)
  introDraw()--intro
end

function point(xin, yin, zin, xrot, yrot, fov)
  xrot = xrot or 0
  yrot = yrot or 0
  fov = fov or 150
  local x = math.cos(xrot)*xin-math.sin(xrot)*yin --*fov/(math.cos(xrot)*yin+math.sin(xrot)*xin*math.sin(yrot)+fov-math.cos(yrot)*zin)
  local y = math.cos(yrot)*(math.cos(xrot)*yin+math.sin(xrot)*xin)+math.sin(yrot)*zin --*fov/(math.cos(xrot)*yin+math.sin(xrot)*xin*math.sin(yrot)+fov-math.cos(yrot)*zin)

  return x, y
end
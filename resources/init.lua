local oo = require 'oo'
local util = require 'util'
local vector = require 'vector'
local constant = require 'constant'
local rect = require 'rect'

local Timer = require 'Timer'
local DynO = require 'DynO'

local czor = world:create_object('Compositor')

local balls = 3

function background()
   czor:clear_with_color(util.rgba(255,255,255,255))
end

local Brick = oo.class(DynO)

function Brick:init(pos, dim)
   DynO.init(self, pos)

   local go = self:go()

   go:add_component('CTestDisplay', {w=dim[1], h=dim[2]})
   go:add_component('CSensor', {fixture={type='rect',
                                         density=100,
                                         w=dim[1], h=dim[2],
                                         restitution=1}})
end

function Brick:update()
end

local Ball = oo.class(DynO)

function Ball:init(pos, vel)
   DynO.init(self, pos)
   local go = self:go()

   vel = vector.new(vel)
   go:vel(vel)

   self.ipos = pos
   self.ivel = vel

   self.dim = {8, 8}
   go:add_component('CTestDisplay', {w=self.dim[1], h=self.dim[1]})
   go:add_component('CSensor', {fixture={type='circle', radius=8, w=8, h=8,
                                         density=0.1, restitution=1,
                                         friction=0}})
end

function Ball:colliding_with(obj)
   if obj:is_a(Brick) then
      local fn = function()
         obj:terminate()
      end
      Timer():reset(0.1, fn)
   end
end

function Ball:update()
   local go = self:go()
   local pos = go:pos()
   if pos[2] < 0 then
      balls = balls - 1
      go:pos(self.ipos)
      go:vel(self.ivel)
   end
end

local Paddle = oo.class(DynO)

function Paddle:init()
   DynO.init(self, {screen_width/2, 32})

   local go = self:go()
   go:body_type(constant.STATIC)

   local w = 64
   local h = 12

   go:add_component('CTestDisplay', {w=w, h=h})
   go:add_component('CSensor', {fixture={type='rect', w=w, h=h}})
end

function Paddle:update()
   local mouse_state = util.mouse_state()
   local pos = self:go():pos()
   pos[1] = mouse_state[1]
   self:go():pos(pos)
end

function gameboard()
   -- walls
   local bottomd = {offset={screen_width/2, 0},
                    w=screen_width, h=10}
   local bottom = {type='edge', p1={0,0}, p2={screen_width,0},
                   friction = 0}

   local topd = {offset={screen_width/2, screen_height},
                 w=screen_width, h=10}
   local top = {type='edge', p1={0,screen_height},
                p2={screen_width,screen_height}, friction=0}

   local leftd = {offset={0, screen_height/2},
                  w=10, h=screen_height}
   local left = {type='edge', p1={0,0}, p2={0,screen_height},
                friction=0}

   local rightd = {offset={screen_width, screen_height/2},
                   w=10, h=screen_height}
   local right = {type='edge', p1={screen_width,0},
                  p2={screen_width,screen_height}, friction=0}

   --stage:add_component('CCollidable', {fixture=bottom})
   stage:add_component('CCollidable', {fixture=top})
   stage:add_component('CCollidable', {fixture=left})
   stage:add_component('CCollidable', {fixture=right})

   --stage:add_component('CTestDisplay', bottomd)
   stage:add_component('CTestDisplay', topd)
   stage:add_component('CTestDisplay', leftd)
   stage:add_component('CTestDisplay', rightd)
end

function bricks()
   local bw = 32
   local bh = 16
   local bs = 8
   local dim = {bw, bh}

   local margin = 32
   local rswidth = screen_width - 2*margin

   local cw = math.floor(rswidth / (bw + bs))
   local ch = 4
   local bswidth = cw * (bw + bs)
   local bsheight = ch * (bh + bs)

   local ox = margin/2 + (rswidth - bswidth) / 2
   local oy = screen_height - bsheight - bh

   local bricks = {}

   for ii=1,ch do
      for jj=1,cw do
         local x = ox + (bw + bs) * jj
         local y = oy + (bh + bs) * ii
         local pos = vector.new({x, y})
         table.insert(bricks, Brick(pos, dim))
      end
   end
   return bricks
end

function level_init()
   util.install_basic_keymap()
   util.install_mouse_map()

   world:gravity({0,0})

   local cam = stage:find_component('Camera', nil)
   cam:pre_render(util.fthread(background))

   gameboard()
   Paddle()

   local all_bricks = bricks()
   local ball = Ball({screen_width/2, 32}, {100, 300})
   local thread = function()
      if balls < 0 then
         for ii, brick in ipairs(all_bricks) do
            brick:terminate()
         end
         local spawn = function()
            all_bricks = bricks()
         end
         Timer():reset(0.1, spawn)
         balls = 3
      end
   end
   stage:add_component('CScripted', {update_thread=util.fthread(thread)})
end

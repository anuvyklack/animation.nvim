local class = require('middleclass')
local modf = math.modf
local floor = math.floor

---Without arguments return a current high-resolution time in milliseconds.
---If `start` is passed, then return the time passed since given time point.
---@param start? number some time point in the past
---@return number time
local function time(start)
   local t = vim.loop.hrtime() / 1e6
   if start then
      t = t - start
   end
   return t
end

---@param x number
---@return integer
local function round(x)
   return floor(x + 0.5)
end

--------------------------------------------------------------------------------

---@class nvim.Animation
---@field _duration integer milliseconds
---@field _period integer Time (ms) between two frames.
---@field _easing fun(ratio: number): number
---@field _callback fun(fraction: number): boolean?
---@field _timer? luv.Timer
---@field _frame integer frame number
---@field _total_time integer
local Animation = class('nvim.Animation')

function Animation:initialize(duration, fps, easing, callback)
   self._duration = duration
   self._period = round(1000 / fps)
   self._easing = easing
   self._callback = callback
end

function Animation:set_callback(callback)
   self._callback = callback
end

function Animation:is_running()
   return self._timer and true or false
end

function Animation:run()
   if self._timer then return end
   self._frame = 0
   self._total_time = 0

   local timer = vim.loop.new_timer()

   timer:start(0, self._period, vim.schedule_wrap(function() self:_tick() end))

   self._timer = timer
end

function Animation:_tick()
   if not self._timer then return end
   self._timer:stop()

   local period, duration = self._period, self._duration
   local elapsed = (self._frame == 0) and period or round(time(self._start))
   local total_time = self._total_time + elapsed
   self._total_time = total_time

   if elapsed == 0 then
      -- print('elapsed = 0')
      self._timer:again()
      return
   end

   self._frame = self._frame + 1

   if total_time >= duration then
      -- print('total > duration ', self._frame, ' elapsed ', elapsed, ' total ', total_time)
      self._callback(1)
      self:finish()
      return
   end

   local ratio = total_time / duration
   local finish = self._callback(self._easing(ratio))
   if finish then
      self:finish()
      return
   end

   local repeat_time
   if total_time > (self._frame + 1) * period then
      local x
      self._frame, x = modf(total_time / period)
      repeat_time = period - x * period
   else
      repeat_time = (self._frame + 1) * period - total_time
   end
   repeat_time = round(repeat_time)
   repeat_time = (repeat_time ~= 0) and repeat_time or period
   self._timer:set_repeat(repeat_time)

   -- print(string.format('%2d   elapsed %2d   repeat %2d   total %3d',
   --                     self._frame, elapsed, repeat_time, total_time))

   self._start = time()
   self._timer:again()
end

function Animation:finish()
   if self._timer then
      self._timer:close()
      self._timer = nil
   end
end

return Animation

--------------------------------------------------------------------------------

---@class luv.Timer
---@field start function
---@field stop function
---@field set_repeat function
---@field again function
---@field close function


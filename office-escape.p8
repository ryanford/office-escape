pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- office escape
function unpack(t,i,...)
	i=i or #t
	if (i==0) return ...
	return unpack(t,i-1,t[i],...)
end

function centerx(str,nglyphs)
	return 64-flr(#str*4)/2-(nglyphs or 0)
end

do
	local charmap={}
	local codes="\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90"
	local ltrs="abcdefghijklmnopqrstuvwxyz"
	for i=1,26 do
		charmap[sub(ltrs,i,i)]=sub(codes,i,i)
	end
	function small(str)
		local newstr=""
		for i=1,#str do
			local c=sub(str,i,i)
			newstr=newstr..(charmap[c] and charmap[c] or c)
		end
		return newstr
	end
end

function outline(str,x,y,c1,c2)
		local pos={-1,1,-1,0,-1,-1,0,-1,0,1,1,1,1,-1,1,0}
		for i=0,7 do
			print(str,x+pos[1+2*i],y+pos[2+2*i],c1)
		end
		print(str,x,y,c2)
end

function split(str)
	local arr={}
	for i=1,#str do
		add(arr,sub(str,i,i))
	end
	return arr
end

class={
	init=function(self)end,
	new=function(self,o)
		o = o or {}
		self.__index=self
		setmetatable(o,self)
		o:init()
		return o
	end
}

function get_distance(x1,y1,x2,y2)
	return sqrt((y2-y1)^2+(x2-x1)^2)
end

clock=class:new{
	old=0,
	now=0,
	dt=0,
	update=function(self)
		self.old=self.now
		self.now=t()
		self.dt=self.now-self.old
	end,
	draw=function(self)

	end,
}

timer=clock:new{
	start=0,
	term=0,
	cb=function() end,
	init=function(self)
		function self.new(self,o)
			o=o or {}
			self.__index=self
			setmetatable(o,self)
			o:init()
			add(timers,o)
			o.start=clock.now
			o.term=o.start+o.term
		end
	end,
	update=function(self)
		if self.term<=clock.now then
			del(timers,self)
			return self:cb(self)
		end
	end,
	draw=function(self)
	end,
}

scorekeeper=class:new{
	kvalue=0,
	hvalue=0,
	value="",
	col=15,
	cols={8,9,10,11,12,14},
	add=function(self,v)
		self.hvalue+=v
	end,
	update=function(self)
		local old=self.kvalue
		self.kvalue+=flr(self.hvalue/10)
		if (flr(old/4)~=flr(self.kvalue/4)) orb:new()
		self.hvalue%=10
		self.value=tostr(self.kvalue>0 and self.kvalue or "")..tostr(self.hvalue).."00"
		if (self.value=="000") self.value="0"
		if not self.highscore then
			if self.kvalue>highscore.kvalue or (self.kvalue==highscore.kvalue and self.hvalue>highscore.hvalue) then
				self.highscore=true
				dset(2,1)
			end
		elseif (clock.now*1000)%2==0 then
			local col
			repeat
				col=self.cols[ceil(rnd()*6)]
			until col~=self.col
			self.col=col
		end
	end,
	draw=function(self)
		outline(self.value,centerx(self.value),21,1,self.col)
	end
}
-->8
-- classes
player=class:new{
	step=0,
	animstep=0,
	animspeed=14,
	frames={
		running={[0]=32,34,36,38,32,40,42,44},
		jumping={[0]=0,2,4,6,8,10,12,14},
		active={}
	},
	jumping=false,
	midair=false,
	x=40,
	y=68,
	w=2,
	h=2,
	dy=0,
	hbx=44,
	hby=76,
	hangtime=0,
	boost=0,
	tmpscore={},
	is_ground=function(self)
		return self.y>=68
	end,
	update=function(self)
		if (self.boost>0) self.boost=max(0,self.boost-clock.dt)
		self.step+=clock.dt*self.animspeed
		self.animstep=flr(self.step)%8
		self.frames.active=(self.midair and self.y<56) and self.frames.jumping or self.frames.running
		--jumping and falling
		if not self.midair and btn(4) then -- jump
			self.jumping=true
			self.dy-=4
			self.jumping=true
			self.midair=true
			sfx(3)
		elseif self.midair then
			if self.jumping and btn(4) then -- continue upward acc
				self.dy-=8*clock.dt
				if (self.dy<-5) self.jumping=false -- max acc / liftoff
			else -- dec
				self.jumping=false
				self.dy+=16*clock.dt
			end
			self.hangtime+=clock.dt
		end
		self.y+=self.dy
		if self.y > 68 then -- land
			self.midair=false
			self.dy=0
			self.y=68
			particle:new{
				x=self.x+4,
				y=self.y+14,
				size=3.5*self.hangtime,
				area=rearmidground
			}
			for obs,bonus in pairs(self.tmpscore) do
				if obs.x+obs.hitbox[3]<player.x+3 then
					score:add(bonus)
					player.tmpscore[obs]=0
				end
			end
			self.hangtime=0
		end
		if self.boost>0 then
			if (flr(clock.now*20)~=flr(clock.old*20)) shadow:new()
		end
	end,
	draw=function(self)
		spr(self.frames.active[self.animstep],self.x,self.y,self.w,self.h)
		if (debug) circ(self.x+7.5,self.y+7.5,7,8)
	end,
}

obstacle=class:new{
	x=127,
	y=68,
	w=2,
	h=2,
	bonus=1,
	cb=function()end,
	init=function(self)
		add(self.area or midground,self)
	end,
	update=function(self)
		local m=spd*clock.dt
		self.x-=m
		local x,y=self.x,self.y
		if x<60 then
			local hb1,hb2,hb3,hb4=unpack(self.hitbox)
			for i=x+hb1,x+hb3 do
		if get_distance(player.x+7.5,player.y+8,i,self.y+hb2)<=3.5 then
				_update=gameover_update
				_draw=gameover_draw
				music(-1)
			end
			end
			for i=y+hb2,y+hb4 do
		if get_distance(player.x+7.5,player.y+8,self.x+hb1,i)<=3.5 then
				_update=gameover_update
				_draw=gameover_draw
				music(-1)
		end
			end
		end
		if self.x==mid(44,self.x,52) then
			if (not player.tmpscore[self]) player.tmpscore[self]=self.bonus*(player.boost>0 and 2 or 1)
		end
		if x<24-self.w*8 then --check offscreen
			score:add(player.tmpscore[self])
			player.tmpscore[self]=nil
			del(self.area or midground,self)
			return self:cb()
		end
	end,
	draw=function(self)
		spr(self.spr,self.x,self.y,self.w,self.h)
		if debug then
			local hbox1,hbox2,hbox3,hbox4=unpack(self.hitbox)
			local x,y = self.x,self.y
			if self.hitbox.shape=="rect" then
				rect(x+hbox1,y+hbox2,x+hbox3,y+hbox4,8)
			end
		end
	end,
}

coworker=obstacle:new{
	hitbox={shape="rect",4,0,12,15},
	init=function(self)
		add(self.area or midground,self)
		self.spr=66+2*flr(rnd(4))
	end
}

watercooler=obstacle:new{
	spr=74,
	h=4,
	y=57,
	bonus=2,
	hitbox={shape="rect",1,0,14,26},
}

cabinet=watercooler:new{
	spr=76,
	y=53,
	bonus=3,
	hitbox={shape="rect",1,0,14,29},
}

server=cabinet:new{
	spr=78
}

dog=obstacle:new{
	spr=64,
	x=128,
	y=62,
	h=3,
	w=2,
	bonus=2,
	hitbox={shape="rect",2,0,14,21},
	update=function(self)
		local x,y=self.x,self.y
		local hb1,hb2,hb3,hb4=unpack(self.hitbox)
		local area={midground,rearmidground,midground}
		for i=1,3 do
			fire:new{
		x=self.x+8*(i-1)+rnd(1),
		y=80,
		size=rnd()*4+1,
		col=({8,8,10})[ceil(rnd(3))],
		area=area[i],
			}
			for i=x+hb1,x+hb3 do
		if get_distance(player.x+8,player.y+8,i,y+hb2)<=3 then
			_update=gameover_update
			_draw=gameover_draw
			music(-1)
			return
		end
			end
			for i=y+hb2,y+hb4 do
		if get_distance(player.x+8,player.y+8,self.x+hb1,i)<=3 then
			_update=gameover_update
			_draw=gameover_draw
			music(-1)
			return
		end
			end
			if self.x==mid(44,self.x,52) then
		if (not player.tmpscore[self]) player.tmpscore[self]=self.bonus*(player.boost>0 and 2 or 1)
			end
		end
		if self.x<0-self.w*8 then
			del(self.area or midground,self)
			player.tmpscore[self]=nil
			return self:cb()
		end
		self.x-=spd*clock.dt
	end,
}

silouette=class:new{
	xs={127,121,133,114,140,115,139,109,145},
	spd=1.6,
	init=function(self)
		self.xs={unpack(self.xs)}
		add(foreground,self)
	end,
	update=function(self)
		local m,xs=spd*self.spd*clock.dt,self.xs

		for i=1,9 do xs[i]-=m end
		if xs[5]<24 then
			del(foreground,self)
		end
	end,
	draw=function(self)
		local xs=self.xs
		circfill(xs[1],72,10,1) -- skull
		circfill(xs[1],78,8,1) -- jaw
		circfill(xs[1],96,13,1) -- traps
		circfill(xs[6],93,6,1) -- left shoulder
		circfill(xs[7],93,6,1) -- right shoulder
		rectfill(xs[8],91,xs[9],104,1) -- body
	end,
}

title_office=class:new{
	x=35,
	y=0,
	draw=function(self)
		spr(137,self.x,flr(self.y),7,2)
	end
}

title_escape=class:new{
	x=-20,
	y=56,
	draw=function(self)
		outline("e s c a p e",self.x,self.y,1,15)
	end
}

bg=class:new{
	x=127,
	y=36,
	w=1,
	spd=.7,
	cb=function(self) chair:new() end,
	init=function(self)
		function self.new(self,o)
			o=o or {}
			self.__index=self
			setmetatable(o,self)
			o:init()
			add(background,o)
			return o
		end
	end,
	update=function(self)
		local m=self.spd*spd*clock.dt
		self.x-=m
		local x,y=self.x,self.y
		if x+self.w*8<24 then
			del(background,self)
			return self:cb()
		end
	end,
	draw=function(self)
		for i,row in pairs(self.tiles) do
			for j,tile in pairs(row) do
				spr(tile,self.x+8*(j-1),self.y+8*(i-1))
			end
		end
	end
}

cubicle1=bg:new{
	tiles={
		{176,128,129,129,129,129,181},
		{128,130,145,145,128,130,146},
		{144,146,145,145,144,146,146},
		{160,162,166,166,160,162,177}
	},
	w=7,
}

cubicle2=cubicle1:new{
	tiles={
		{176,128,129,129,129,129,181},
		{128,129,129,130,145,145,164},
		{144,145,145,146,145,145,164},
		{160,161,161,162,165,165,178}
	}
}

chair=bg:new{
	y=48,
	w=2,
	init=function(self)
		self.spr=131+flr(rnd(2))*2
		self.y=48+flr(rnd(8))
	end,
	draw=function(self)
		spr(self.spr,self.x,self.y,2,2)
	end,
}

wallclock=bg:new{
	y=36,
	cb=function(self) chair:new() end,
	draw=function(self)
		spr(135,self.x,self.y)
	end,
}

do
	local decor={cubicle1,cubicle2,chair,wallclock}

	function spawnbg()
		local item=decor[ceil(rnd(#decor))]
		item:new{cb=spawnbg}
	end
end

orb=class:new{
	x=127,
	y=36,
	pal={8,9,11,12,14},
	col=11,
	size=2,
	old={x=127,y=36},
	init=function(self)
		function self.new(self,o)
			o=o or {}
			self.__index=self
			setmetatable(o,self)
			o:init()
			add(midground,o)
			return o
		end
	end,
	update=function(self)
		self.old.x=self.x
		self.old.y=self.y
		self.y=36+cos(clock.now)*3
		self.x-=spd*clock.dt
		self.col=self.pal[ceil(rnd(5))]
		if get_distance(player.x+7.5,player.y+8,self.x+1,self.y+1)<=4.5 then
	player.boost+=30
	del(midground,self)
	music(12)
	end
		if (self.x<20) del(midground,self)
	end,
	draw=function(self)
		circfill(self.x,self.y,self.size,self.col)
	end
}
-->8
--groups
groups={
	{coworker,coworker,coworker},
	{coworker,coworker},
	{coworker,watercooler,coworker},
	{server,server,server},
	{cabinet,cabinet},
	{dog},
	{coworker},
	{cabinet},
	{server},
	{watercooler}
}

function spawn()
	local obs=groups[ceil(rnd(#groups))]
	if #obs==1 then
		obs[1]:new{cb=spawn}
	else
		for i,o in pairs(obs) do
			timer:new{
				term=.9*(i-1)+spd/80,
				cb=function()
					o:new{cb=(i==#obs and spawn or nil)}
				end
			}
		end
	end
end
-->8
--juice
particle=class:new{
	t=1,
	size=3,
	rate=20,
	col=6,
	x=64,
	dx=1,
	y=82,
	dy=0,
	init=function(self)
		add(self.area,self)
	end,
	update=function(self)
		self.t-=clock.dt
		self.x+=self.dx*(rnd()>0.5 and -1 or 1)
		self.x-=spd*clock.dt
		self.y-=self.dy*(rnd()>0.3 and 1 or 0)
		self.size-=clock.dt*self.rate
		if (self.t<=0 or self.size<1) del(self.area,self)
	end,
	draw=function(self)
		circfill(self.x,self.y,flr(self.size),self.col)
	end,
}

fire=particle:new{
	size=4,
	rate=10,
	t=1,
	dy=0.3,
	dy=3,
}

fireworks=class:new{
	sparks={},
	init=function(self)
		function self.new(self,o)
			o=o or {}
			self.__index=self
			setmetatable(o,self)
			for i=1,(o.size or 35) do
				add(o.sparks,{
					x=o.x,
					y=o.y,
					dx=rnd(30)-15,
					dy=rnd(30)-15,
					col=flr(rnd(8))+8,
					t=rnd(100)
				})
			end
			add(foreground,o)
			return o
		end
	end,
	update=function(self)
		foreach(self.sparks,function(spark)
			spark.x+=spark.dx*clock.dt
			spark.y+=spark.dy*clock.dt
			spark.dy+=.05
			spark.t-=1
			if (spark.t<=0) del(self.sparks,spark)
		end)
		if (#self.sparks==0) del(foreground,self)
	end,
	draw=function(self)
		foreach(self.sparks,function(spark)
	pset(spark.x,spark.y,spark.col)
		end)
	end
}

shadow=class:new{
	pals={
		{2,8,14},
		{4,9,15},
		{13,12,6}
	},
	init=function(self)
		function self.new(self,o)
			o=o or {}
			self.__index=self
			setmetatable(o,self)
			o:init()
			o.x=player.x
			o.y=player.y
			o.sprite=player.frames.active[player.animstep]
			o.col=ceil(rnd(3))
			add(rearmidground,o)
			return o
		end
	end,
	update=function(self)
		self.x-=spd*clock.dt
		if (self.x<=8) del(rearmidground,self)
	end,
	draw=function(self)
		local p1={1,3,13}
		local p2=self.pals[self.col]
		for i=1,3 do
			pal(p1[i],p2[i])
		end
		spr(self.sprite,self.x,self.y,2,2)
		for i=1,3 do
			pal(p1[i],p1[i])
		end
	end
}
-->8
--intro
intro_scene=cocreate(function()
repeat
		yield()
		yield()
		highscore={
			kvalue=dget(0),
			hvalue=dget(1)
		}
		has_score=dget(2)~=0
		local title_office=title_office:new()
		local title_escape=title_escape:new()
		do
			local m=1
			repeat
				title_office.y=min(title_office.y+clock.dt*10*m,36)
				m*=1.04
				yield()
				title_office:draw()
				yield()
			until title_office.y==36 or btnp(4)
			title_office.y=36
		end
		do
			local m=1
			local target=centerx("e s c a p e")
			repeat
		title_escape.x=min(title_escape.x+clock.dt*10*m,target)
		m*=1.4
		yield()
		title_office:draw()
		title_escape:draw()
		yield()
			until title_escape.x==target or btnp(4)
			title_escape.x=target
		end
		do
			local wait=clock.now+1
			repeat
				yield()
				title_office:draw()
				title_escape:draw()
				yield()
			until clock.now>wait or btn(4)
		end
		do
			local wavy={}
			local str1="\x8e  to start"
			local strx=centerx(str1)
			local hs=tostr(highscore.kvalue>0 and highscore.kvalue or "")..tostr(highscore.hvalue).."00"
			for i=1,#str1 do
				local c=sub(str1,i,i)
				add(wavy,{c=c,x=strx+4*(i-1),y=80})
			end
			repeat
				for i,char in pairs(wavy) do
			char.y=(has_score and 70 or 80)+cos(clock.now+i*(1/#wavy))*1.4
				end
				yield()
				title_office:draw()
				title_escape:draw()
				for i,char in pairs(wavy) do
			print(char.c,char.x,char.y,1)
				end
				if has_score then
					local str1=small("best")
					print(str1,centerx(str1),82,1)
					print(hs,centerx(hs),88,1)
				end
				yield()
			until btnp(4)
		end
		do
			local wait=clock.now+0.1
			repeat yield() until clock.now>=wait
			music(-1)
			music(0)
			game_start()
		end
	until false
end)

function intro_update()
	clock:update()
	if costatus(intro_scene)~="dead" then
		coresume(intro_scene)
	end
end

function intro_draw()
	cls(1)
	rectfill(24,24,104,104,15)
	if costatus(intro_scene)~="dead" then
		coresume(intro_scene)
	end
	rectfill(0,24,24,104,1) -- blinders
	rectfill(104,24,127,104,1) -- blinders
	rectfill(24,0,104,24,1) -- blinders
end
-->8
--gameplay

function game_update()
	clock:update()
	if stat(18)==9 and stat(19)==15 then
		if (stat(23)==31) music(13)
	end
	spd=50+10*(score.kvalue*10+score.hvalue-spdmod)*clock.dt
	if flr(clock.now)~=flr(clock.old) and #foreground<4 then
		if (rnd()>.5) silouette:new{spd=rnd()+1.3}
	end
	for group in all{timers,foreground,rearmidground,midground,background} do
		for x in all(group) do
			if (x.update) x:update()
		end
	end
	if (clock.now>tiptime+7) tip=""
	player:update()
	score:update()
end

function game_draw()
	cls(1)
	rectfill(24,24,104,104,15)
	line(24,60,104,60,1)
	for group in all{timers,background,rearmidground,midground} do
		for x in all(group) do
			if (x.draw) x:draw()
		end
	end
	player:draw()
	for x in all(foreground) do x:draw() end
	rectfill(0,24,24,104,1) -- blinders
	rectfill(104,24,127,104,1) -- blinders
	if debug then
		print(#background,10,111,7) --bottom left
		print(#rearmidground,20,111,7) --bottom left
		print(#midground,30,111,7) --bottom left
		print(#foreground,40,111,7) --bottom left
		line(48,24,48,104,11)
		line(24,player.y+12,104,player.y+12,12)
		print(flr(spd),10,117,7) -- bottom left
		print(clock.now,10,123,7) -- bottom left
	end
	score:draw()
	outline(tip,33,103,1,15)
end
-->8
--gameover
gameover_scene=cocreate(function()
	repeat
		yield()
		foreground={}
		newhighscore=nil
		if score.kvalue>highscore.kvalue or (score.kvalue==highscore.kvalue and score.hvalue>highscore.hvalue) then
			dset(0,score.kvalue)
			dset(1,score.hvalue)
			newhighscore=true
			music(12)
		end
		repeat
			yield()
			yield()
		until stat(16)~=16
		if (not newhighscore) sfx(24)
		repeat
			if newhighscore then
				foreach(foreground,function(fworks)
			fworks:update()
				end)
				if (flr(clock.now)~=flr(clock.old)) fireworks:new{x=rnd(79)+24,y=rnd(79)+24,size=flr(rnd(25))+10}
			end
			yield()
			print("game over",centerx("game over"),newhighscore and 48 or 63,1)
			if newhighscore then
				local str1="new high score"
				local score=score or {value="hello"}
				print(str1,centerx(str1),63,1)
				print(score.value,centerx(score.value),78,1)
				foreach(foreground,function(fworks)
			fworks:draw()
				end)
			end
			yield()
		until btnp(4)
		music(-1)
		sfx(-1)
		music(13)
		_update=intro_update
		_draw=intro_draw
		yield()
	until false
end)

function gameover_update()
	clock:update()
	coresume(gameover_scene)
end

function gameover_draw()
	cls(1)
	rectfill(24,24,104,104,15)
	coresume(gameover_scene)
end
-->8
function _init()
-- debug=true
	cartdata("office_escape")
	if debug then
		dset(0,0)
		dset(1,0)
		dset(2,0)
	end
	highscore={
		kvalue=dget(0),
		hvalue=dget(1)
	}
	has_score=dget(2)~=0
	if not debug then
		if highscore.kvalue<2 then
			dset(0,2)
			highscore.kvalue=2
		end
	end
	palt(14,true)
	palt(0,false)
	music(13)
	tip="press \x8e to jump"

	_update=intro_update
	_draw=intro_draw
end

function game_start()
	score=scorekeeper:new()
	spd=40
	spdmod=0
	player.boost=0
	tip="press \x8e to jump"
	tiptime=clock.now
	foreground={}
	rearmidground={}
	midground={}
	background={}
	timers={}
	spawnbg()
	spawn()
	_update=game_update
	_draw=game_draw
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeee111eeeeeeeeeeeeeeeeeeeeeeeeee111eeeeeeeeeeeeeee11111eeeeeeeeeeeeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeee
eeeeee1dd11eeeeeeeeeeeeeeeeeeeeeeee11133eeeeeeeeeeeee1111111eeeeeeeeeeeee3111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1ddddddeeeee
eeeee1dd6d11eeeeeee133dd3ed11eeeee11133ddeeeeeeeeeeee3111113eeeeeeeeeeedd33111eeeeeeeee333eeeeeeeeee11ddeeeeeeeeeeee1d61d61eeeee
eeeeeedd1dd1eeeeee1113dd3dddd1eeee11333dd3e1eeeeeeeee3311133eeeeeeeeeeedd33311eeee1d1de3dd331eeeeee11d61deeeeeeeeeeedddddddeeeee
eeeee3dddd6deeeeee1111333dd6d1eeee1333333ddd1eeeeeee3dd333ddeeeeeeeeeee3333331eeee1d6dd3dd3111eeee11dddddeeeeeeeeeeeedddddeeeeee
eeeedd3ddd1deeeeee1111333dd1d1eeeeeedd33ddddd1eeeeee3dd333ddeeeeeeeeeddd33dd3eeeee1dddd3331111eeee1d61ddd3ddeeeeeeee33333333eeee
eee3dd33dddeeeeeee1111333dddd1eeeeeedd3ddd16d1eeeeee33333333eeeeeeeed1ddd3ddeeeeee1d1dd3331111eeee1ddddd33ddeeeeeeeedd333dd3eeee
ee1333333eeeeeeeee1113dd3dd6d1eeeeeeeeeddddd11eeeeeeeedddddeeeeeeeeed6dddd3eeeeeee1d6dd3331111eeeee1ddd3333331eeeeeedd333dd3eeee
ee11333ddeeeeeeeeee133dd3ed1d1eeeeeeeeed16d11eeeeeeeedddddddeeeeeeee1dd1ddeeeeeeee1dddd3dd3111eeeeee1e3dd33311eeeeee3311133eeeee
ee11133ddeeeeeeeeeeeee333eeeeeeeeeeeeeeedd11eeeeeeeee16d16d1eeeeeeee11d6dd1eeeeeeee11de3dd331eeeeeeeeeedd33111eeeeee3111113eeeee
eee1113eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedddddd1eeeeeeeee11dd1eeeeeeeeeeeeeeeeeeeeeeeeeeeeee33111eeeeeee1111111eeeee
eeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111eeeeeeeee11111eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeee111111eeeeeeeee1ddddddeeeeeeeeee111111eeeeeeeeee111111eeeeeeeee1ddddddeeeeeeeeee111111eeeeeeeeeeeeeeeeeeeee
eeeee111111eeeeeeeee1ddddddeeeeeeeee1d61d61eeeeeeeee1ddddddeeeeeeeee1ddddddeeeeeeeee1d61d61eeeeeeeee1ddddddeeeeeeeeeeeeeeeeeeeee
eeee1ddddddeeeeeeeee1d61d61eeeeeeeeedddddddeeeeeeeee1d61d61eeeeeeeee1d61d61eeeeeeeeedddddddeeeeeeeee1d61d61eeeeeeeeeeeeeeeeeeeee
eeee1d61d61eeeeeeeeedddddddeeeeeeeeeedddddeeeeeeeeeedddddddeeeeeeeeedddddddeeeeeeeeeedddddeeeeeeeeeedddddddeeeeeeeeeeeeeeeeeeeee
eeeedddddddeeeeeeeeeedddddeeeeeeeee333333333eeeeeeeeedddddeeeeeeeeeeedddddeeeeeeeeee3333333eeeeeeeeeedddddeeeeeeeeeeeeeeeeeeeeee
eeeeedddddeeeeeeeeee3333333eeeeeee3333333333ddeeeeee3333333eeeeeeeee3333333eeeeeeeee33dd333eeeeeeeee3333333eeeeeeeeeeeeeeeeeeeee
eeee3333333eeeeeeee333333333eeeeedd333333333ddeeeee333333333eeeeeeee3333333eeeeeeeee33dd333eeeeeeeee3333333eeeeeeeeeeeeeeeeeeeee
eee333333333eeeeee333333333ddeeeedde3333333eeeeeeedd3333333ddeeeeeee3333333eeeeeeeee3333333eeeeeeeee3333333eeeeeeeeeeeeeeeeeeeee
eee333333333eeeeeedd3333333ddeeeeeee3333333eeeeeeedd3333333ddeeeeeee33dd333eeeeeeeee3333333eeeeeeeee33dd333eeeeeeeeeeeeeeeeeeeee
eeedd3333333eeeeeedd3333333eeeeeeeee111111eeeeeeeeee3333333eeeeeeeee33dd333eeeeeeee111111111eeeeeeee33dd333eeeeeeeeeeeeeeeeeeeee
eeedd333333deeeeeeee3333111eeeeeeeeeee111eeeeeeeeeee111111eeeeeeeeee3333333eeeeeee1111eee1111eeeee111133333eeeeeeeeeeeeeeeeeeeee
eeee3333333eeeeeeeeee11111eeeeeeeeeeeee1eeeeeeeeeeeee1111eeeeeeeeeee1111111eeeeeee11eeeeee111eeeeee11111111eeeeeeeeeeeeeeeeeeeee
eeee111e111eeeeeeeeeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeee11eeeeeeeeeee111ee1111eeeeeeeeeeeeeeeeeeeeeeeeeeee111eeeeeeeeeeeeeeeeeeeee
eeee11eee11eeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1eeeeeeeeeee11eeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeee11eeeeeeeeeeeeeeeeeeeee
eeee1eeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeee
eeee4444eeeeeeeeeeeee2222222eeeeeeee00000000eeeeeeeee4444444eeeeeeeeddddddddeeeeeeedddddddddddeeeee11111111111eeeee00000000000ee
eeee4444eeeeeeeeeeee222222222eeeeeeee0dddd000eeeeeee444444444eeeeeeeed2222dddeeeeedeeeeeeeeeeedeee1dddddddddd11eee0111111111100e
eee411114eeeeeeeeeee2d2ddd2222eeeeeeedddddd00eeeeeee4242224444eeeeeee222222ddeeeeedeeeeeeeeeeedee1dddddddddd1d1ee01111111111010e
eee4444449eeeeeeeee22dddddd222eeeeeee16d16d00eeeeee44222222444eeeeeee162162ddeeeeedeeeeeeeeeeedee11111111111dd1ee00000000000110e
eeee9999999eeeeeeee2216d16d222eeeeeeeddddddd0eeeeee44162162444eeeeeee2222222deeeeedeeeeeeeeeeedee1ddddddddd1dd1ee01111111110110e
eeee99977977eeeeeee22ddddddd22eeeeeeeedddddeeeeeeee44222222244eeeeeeee22222eeeeeeedeeeeeeeeeeedee1ddddddddd1dd1ee01111111110110e
eee919711711eeeeeee222ddddd22eeeeeeee0000000eeeeeee4442222244eeeeeeee6611666eeeeeedcccccccccccdee1ddddddddd1dd1ee0110c00b110110e
eee1117117119eeeeeee2111111122eeeeee000000000eeeeeee4ddddddd44eeeeee666166666eeeeedcccccccccccdee1ddd111ddd1dd1ee01111111110110e
ee4111999999911eeeee1111111112eeeeee000000000eeeeeeeddddddddd4eeeeee666166666eeeeedcccccccccccdee1ddddddddd1dd1ee01111111110110e
ee4111999999911eeeee111111111eeeeeee0000000ddeeeeeeedddddddddeeeeeee666166622eeeeedcccccccccccdee1ddddddddd1dd1ee011000c0110110e
ee411999999999eeeeee1111111ddeeeeeeed000000ddeeeeeeeddddddd22eeeeeee266666622eeeeeedddddddddddeee1ddddddddd1dd1ee01111111110110e
ee4499999999eeeeeeeed555555ddeeeeeeee1111111eeeeeeee2dddddd22eeeeeeee1111111eeeeeedcccccccccccdee11111111111dd1ee01111111110110e
ee4499999999eeeeeeeee5555555eeeeeeeee1111111eeeeeeeee1111111eeeeeeeee1111111eeeeeedcccccccccccdee1ddddddddd1dd1ee01100bc0110110e
ee4499999999eeeeeeeee5555555eeeeeeeee1111111eeeeeeeee111e111eeeeeeeee1111111eeeeeeedddddddddddeee1ddddddddd1dd1ee01111111110110e
ee4499999999eeeeeeeeedddedddeeeeeeeee111e111eeeeeeeee11eee11eeeeeeeee111e111eeeeeee66666666666eee1ddddddddd1dd1ee01111111110110e
ee444999999999eeeeeeeddeeeddeeeeeeeee11eee11eeeeeeeee1eeeee1eeeeeeeee11eee11eeeeee6666666666666ee1ddd111ddd1dd1ee011cc0c0110110e
eeee44444944e9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666ee1ddddddddd1dd1ee01111111110110e
eeee44444994e99eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666ee1ddddddddd1dd1ee01111111110110e
eeee4ee1e4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666ccd886666ee1ddddddddd1dd1ee0110c000110110e
eeee4ee1e4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666ddddd6666ee1ddddddddd1dd1ee01111111110110e
eeee4ee1e4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666ddddd6666ee11111111111dd1ee01111111110110e
eeee4ee1e4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666ddddd6666ee1ddddddddd1dd1ee0110b000110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666ee1ddddddddd1dd1ee01111111110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666ee1ddddddddd1dd1ee01111111110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666666666666ee1ddd111ddd1dd1ee011c00c0110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee66666666666eee1ddddddddd1dd1ee01111111110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1ddddddddd1dd1ee01111111110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1ddddddddd1dd1ee01111111110110e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1ddddddddd1d1eee0111111111010ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11111111111eeeee00000000000eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
111111111111111111111111eeeee22222222eeeeeeee2222eeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111eeeeeeeeeeeeeeeeeeeeeeeeeee
166666666666666666666661eeee2222222222eeeeee222222eeeeeee077770eeeeeeeeeeeee111111eeeeee11111eee1cccc1111eeee1111111eeeeee1111ee
166666666666666666666661eeee2222222222eeeee2222222eeeeee07777770eeeeeeeeeee1cccccc1eee11ccccc1e1ccccc1ccc1ee1ccccccc1eee11cccc1e
166666666666666666666661eeee2222222222eeeee2222222eeeeee07700770eeeeeeeeee1cccccccc1e1cccccccc1ccccccccccc11ccccccccc1e1ccccccc1
166666666666666666666661eeee2222222222eeeee2222222eeeeee07707070eeeeeeeee1cccccccccc1ccccccccccccccccccccc11ccccccccc11cccccccc1
166666666666666666666661eeeee22222222eeeeeee222222eeeeee07707770eeeeeeee1ccccccccccc1cccccccccccc1111ccccc1cccccccccc1ccccccccc1
166666666666666666666661eeeeee222222eeeeeeee02222eeeeeeee070770eeeeeeeee1cccc111cccc1cccc1111cccc1111ccccc1ccccc11ccc1ccccc1111e
166666666666666666666661eeeeeeee00eeeeeeeeee00eeeeeeeeeeee0000eeeeeeeeee1ccc1eee1ccc1cccc111cccccccc1ccccc1cccc1e1cc1cccccc111ee
166666666666666666666661eeee2222222222eeeee222222222eeeeeeeeeeeeeeeeeeee1dcd1eee1dcdcdcdccc1cdcdcd111dcdcd1dcdc1e1111dcdcdccc1ee
166666666666666666666661eee222222222222eee22222222222eeeeeeeeeeeeeeeeeee1ccc1eee1cccccccc111ccccc1ee1ccccc1cccc1e1cc1cccccc111ee
166666666666666666666661eeee2222222222eeeee222222222eeeeeeeeeeeeeeeeeeee1dcdc111cdcd1dcdc1ee1dcdcd1e1dcdcd1dcdc111cdc1cdcdc1111e
166666666666666666666661eeeeeeee00eeeeeeeeee0000000eeeeeeeeeeeeeeeeeeeeee1dddddddddd1dddd1ee1ddddd1e1ddddd11ddddddddd1ddddddddd1
166666666666666666666661eeeeeeee00eeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeee1cdcdcdcdcd1dcdcd1e1dcdcd1ee1cdc1ee1dcdcdcdc11dcdcdcdc1
166666666666666666666661eeeeeeee00eeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeee1dddddddd1e1dddd1ee1dd11eeee111eeee1ddddddd1e1ddddddd1
166666666666666666666661eeeeee000000eeeeeeee000000eeeeeeeeeeeeeeeeeeeeeeeee1ddddd11eee1111eeee11eeeeeeeeeeeeee1ddddd1eee11dddd1e
166666666666666666666661eeeee0eeeeee0eeeeee0eeeeee0eeeeeeeeeeeeeeeeeeeeeeeee11111eeeeeeeeeeeeeeeeeeeeeeeeeeeeee11111eeeeee1111ee
1666666666666666666666611eeeeee116666661eeeeeeee11111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1666666666666666666666611eeeee1116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1666666666666666666666611eeee16116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1666666666666666666666611eee166116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1666666666666666666666611ee1666116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1666666666666666666666611e16666116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1666666666666666666666611166666116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1111111111111111111111111666666116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeee166666661166666616666666111111111111111111111111116666661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee166666661e1666661e6666661666666616666666111eeeeee116666616eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee166666661ee166661ee6666616666666166666661611eeeeee116666166eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee166666661eee16661eee6666166666661666666616611eeeeee116661666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee166666661eeee1661eeee6661666666616666666166611eeeeee116616666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee166666661eeeee161eeeee6616666666166666661666611eeeeee116166666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e166666661eeeeee11eeeeee6166666661666666616666611eeeeee111666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
166666661eeeeeee1eeeeeee1666666616666666166666611eeeeee111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffff1111ffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffff111111ffffff11111fff1cccc1111ffff1111111ffffff1111fffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffff1cccccc1fff11ccccc1f1ccccc1ccc1ff1ccccccc1fff11cccc1ffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffff1cccccccc1f1cccccccc1ccccccccccc11ccccccccc1f1ccccccc1fffffffffffff111111111111111111111111
1111111111111111111111111fffffffffff1cccccccccc1ccccccccccccccccccccc11ccccccccc11cccccccc1fffffffffffff111111111111111111111111
1111111111111111111111111ffffffffff1ccccccccccc1cccccccccccc1111ccccc1cccccccccc1ccccccccc1fffffffffffff111111111111111111111111
1111111111111111111111111ffffffffff1cccc111cccc1cccc1111cccc1111ccccc1ccccc11ccc1ccccc1111ffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffff1ccc1fff1ccc1cccc111cccccccc1ccccc1cccc1f1cc1cccccc111fffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffff1dcd1fff1dcdcdcdccc1cdcdcd111dcdcd1dcdc1f1111dcdcdccc1fffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffff1ccc1fff1cccccccc111ccccc1ff1ccccc1cccc1f1cc1cccccc111fffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffff1dcdc111cdcd1dcdc1ff1dcdcd1f1dcdcd1dcdc111cdc1cdcdc1111ffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffff1dddddddddd1dddd1ff1ddddd1f1ddddd11ddddddddd1ddddddddd1fffffffffffff111111111111111111111111
1111111111111111111111111fffffffffff1cdcdcdcdcd1dcdcd1f1dcdcd1ff1cdc1ff1dcdcdcdc11dcdcdcdc1fffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffff1dddddddd1f1dddd1ff1dd11ffff111ffff1ddddddd1f1ddddddd1fffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffff1ddddd11fff1111ffff11ffffffffffffff1ddddd1fff11dddd1ffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffff11111ffffffffffffffffffffffffffffff11111ffffff1111fffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff11111ffff1111ffff1111fff11111fff11111fff11111ffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff1fff1fff11ff1fff11ff1fff1fff1fff1fff1fff1fff1ffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff1f111fff1f111fff1f111fff1f1f1fff1f1f1fff1f111ffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff1ff1ffff1fff1fff1f1fffff1fff1fff1fff1fff1ff1fffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff1f111fff111f1fff1f111fff1f1f1fff1f111fff1f111ffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff1fff1fff1ff11fff11ff1fff1f1f1fff1f1fffff1fff1ffffffffffffffffff111111111111111111111111
1111111111111111111111111ffffffffffffffff11111fff1111fffff1111fff11111fff111fffff11111ffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
1111111111111111111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000
__map__
00000000000000000000a2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b08081818181b50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000808181829191a40000838400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000090919192a1a1a40000939400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8787a0a1a1a2a5a5b28700870087008700870087000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200000cd700c0510c0510005100041000350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003065500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001a12500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000475105751057510575605751057510675107751097510c7510e7511075111751147511575115751157511575538700387013770137701367003470032700307002c7002970022700197000e70007700
000100001f7011c7011a701187011570113701107010e7010d7010c7010b7010b7010a70109701097010870108701087050000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018850000000c0550000018850000000c0551805518850180550c0550000018850000000c0550000018850000000c0550000018850000000c0551b05518850130550c05500000188500f0551305518055
011000001b125001001b125001001b125001001b125001001b125001001812500100181250010018125001001d125001001d125001001d125001001d1201f1211d12500100181250010018125001001812500100
011000001f42500405004050040500405004052242500405004050040500405004051f42500405004050040500405004052242500405004050040500405004051f42500405004050040520425004050040500405
0108001018600000000c9150000018925000000c9150000030633000000c9150000018925000000c9150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002744500000000002731500000000002701500000000002701500000000002701500000244450000000000243150000000000240150000000000240150000000000240150000000000000002244500000
011000002444522015000002431522015000002431500000000002401522445000000000022015244450000000000243150000000000240150000000000240150000000000240150000000000240150000000000
011000001f125001001f125001001f125001001f125001001f125001001b125001001b125001001b12500100201250010020125001002012500100201202212120125001001f125001001f125001001f12500100
01100000241250010024125001002412500100241250010024125001001f1250010020125001002212500100241250010024125001002412500100241202612124125001001f125001001f125001001f12500100
010800000c050000000c00000000000001880000000000000c0500c0000000000000000001880000000000000c0500c00000000000000c0501880000000000000c050000000c050000000c0550c0550c0550c055
010f00000c1100e1110f11110111111111211113111141111511117111181111a1111b1111c1111d1111f11124111001010010100101241110010100101001010010100101001010010100101001010010100101
01100000241212412024122241220010000100001001f1242412124120221202212000100001001f1201f1211f1201f1201f1221f122001000010000100001001b1201b1201d1201d1201f1211f1201d1221d120
011000001d1201d1221d122001001b1201b1221d1201d1201f1211f1221d1201d1200010000100181201812018122181221812218122171211612115121141211312100100001000010000100001000010000100
01100000241212412024122241220010000100001001f1242412124120221202212000100001001f1201f1211f1201f1201f1221f122001000010000100001001b1201b1201d1201d1201f1211f1202212222120
01100000221202212222122001001f1201f1222212022120271212712222120221200010000100241202412024122241222412224122231212212121121201211f12100100001000010000100001000010000100
011000001d1201d1221d122001001b1201b1221d1201d1201f1211f1221d1201d120001000010018120181201812218122181221812217121161211512114121131210010000100001001b1201d1201f12022120
01100000241202412024122241220010000100001001f004271202712022120221200010000100241202712024120241202412224122001000010000100001001b1201b1201d1201d120221201f1201d1221f120
01100000221202212222122001001f1201f122221202212029122291222712024120221201f120241202712124121241222412224122231212212121121201211f12100100001000010000100001000010000100
__music__
00 0849494b
00 0849494b
00 080c494b
00 080d494b
00 080c494b
00 080d494b
00 080c094b
00 080d094b
00 080c094b
00 080d094b
00 080c090e
00 080d090f
00 10114344
01 080b0c44
00 080b0d44
00 080b0c44
00 080b0d44
00 080b0c44
00 080b0d44
00 080b0c44
00 080b0d44
00 080b0c12
00 080b0d13
00 080b0c14
00 080b0d15
00 080b0c12
00 080b0d16
00 080b0c17
00 080b0d18
00 080b0c12
00 080b0d13
00 080b0c14
00 080b0d15
00 080b0c12
00 080b0d16
00 080b0c17
02 080b0d18


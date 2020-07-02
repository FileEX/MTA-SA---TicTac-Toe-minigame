--[[
	Author: FileEX
]]

local tc = {};
setmetatable(tc, {__call = function(o, ...) return o:constructor(...); end, __index = tc});

local screenX, screenY = guiGetScreenSize();

local tex = {
	['X'] = dxCreateTexture('img/x.png', 'argb', false, 'clamp'),
	['O'] = dxCreateTexture('img/o.png', 'argb', false, 'clamp'),
};

local num = 3; -- 3 x 3

local tct;

local rend = {
	['board'] = {
		screenX / 2,
		screenY / 2,

		(80 / 1280) * screenX, -- field w
		(80 / 800) * screenY, -- field h

		(450 / 1280) * screenX, -- board w
		(450 / 800) * screenY, -- board h
	},

	['text'] = {
		player = {
			(20 / 1280) * screenX,
			(20 / 800) * screenY,
		},

		result = {

		},
	},
};

local multX = rend['board'][3] + (10 / 1280) * screenX;
local multY = rend['board'][4] + (10 / 800) * screenY;

local posX = rend['board'][1] - rend['board'][5] / 2;
local posY = rend['board'][2] - rend['board'][6] / 2;

local lineWidth = (3 / 1280) * screenX;

function tc:constructor()
	self.__init = function()
		self.players = {};
		self.result = '';
		self.fields = {};
		self.symbols = {};
		self.tick = false;
		self.sToDraw = 0;
		self.turn = 1;
		self.winnerCombination = 0;
		self.gameState = 1;
	end

	self.newGame = function()
		for iX = 1,num do
			for iY = 1,num do -- 60x60 one field
				local pX = posX + iX * multX;
				local pY = posY + iY * multY;
				table.insert(self.fields, {x = pX, y = pY, ex = pX + rend['board'][3], ey = pY + rend['board'][4], checked = nil});
			end
		end

		self.draw = function() self:render(self); end;
		self.onClick = function(b,s) self:click(b,s,self); end;

		showCursor(true, false);

		addEventHandler('onClientRender', root, self.draw);
		addEventHandler('onClientClick', root, self.onClick);
	end

	self.newRound = function()
		self.gameState = 2;

		setTimer(function()
			for i = 1,#self.fields do
				self.fields[i].checked = nil;
			end

			self.tick = false;
			self.sToDraw = 0;

			for k,v in pairs(self.symbols) do
				table.remove(self.symbols, k);
			end
			self.symbols = {};

			self.result = (self.players[1].wins or 0)..':'..(self.players[2].wins or 0);

			self.turn = 1;
			self.gameState = 1;
			self.winnerCombination = 0;

			if (self.players[2].isStarter) then
				local symbol = self.players[2].isStarter and 'X' or 'O';
				self.players[1].symbol = symbol;

				if (symbol == 'X') then
					self.players[2].symbol = 'O';
				else
					self.players[2].symbol = 'X';
				end

				triggerServerEvent('updateData', self.players[2].data, symbol);
			end
		end, 5000, 1);
	end

	self.insertPlayer = function(_, player, sm, st)
		if #self.players < 2 then
			table.insert(self.players, {name = getPlayerName(player), wins = 0, symbol = sm, data = player, isStarter = st});
		end

		self.result = '0:0';
	end

	self.setFieldStatus = function(_, field, s)
		self.fields[field].checked = s;
		--print('symbol: ', s);
		self:animChecking(field, s, self.fields[field].x, self.fields[field].y);
		self:checkResult();
	end

	self.animChecking = function(_, f,s,px,py)
		--print('symbol check: ', s);

		table.insert(self.symbols, {id = f, w = 0, h = 0, i = s, x = px, y = py});
		self:insertNewSymbol(#self.symbols);
	end

	self.insertNewSymbol = function(_, key)
		self.tick = getTickCount();
		self.sToDraw = key;
	end

	self.__init();
	return self;
end

function tc:getWinnerCombination()
	local combine = {};
	local f = self.fields;

	-- vertical
	if (f[1].checked == f[2].checked and f[2].checked == f[3].checked) and f[1].checked ~= nil then
		combine[1] = {startField = 1, endField = 3};
	elseif (f[4].checked == f[5].checked and f[5].checked == f[6].checked) and f[4].checked ~= nil then
		combine[1] = {startField = 4, endField = 6};
	elseif (f[7].checked == f[8].checked and f[8].checked == f[9].checked) and f[7].checked ~= nil then
		combine[1] = {startField = 7, endField = 9};
	-- horizontal
	elseif (f[1].checked == f[4].checked and f[4].checked == f[7].checked) and f[1].checked ~= nil then
		combine[1] = {startField = 1, endField = 7};
	elseif (f[2].checked == f[5].checked and f[5].checked == f[8].checked) and f[2].checked ~= nil then
		combine[1] = {startField = 2, endField = 8};
	elseif (f[3].checked == f[6].checked and f[6].checked == f[9].checked) and f[3].checked ~= nil then
		combine[1] = {startField = 3, endField = 9};
	-- diagonal
	elseif (f[1].checked == f[5].checked and f[5].checked == f[9].checked) and f[1].checked ~= nil then
		combine[1] = {startField = 1, endField = 9};
	elseif (f[3].checked == f[5].checked and f[5].checked == f[7].checked) and f[3].checked ~= nil then
		combine[1] = {startField = 3, endField = 7};
	end

	return combine;
end

function tc:checkResult()
	local f = self.fields;
	local pS,p2S = self.players[1].symbol, self.players[2].symbol;

	if ((f[1].checked == pS and f[2].checked == pS and f[3].checked == pS) or
		(f[4].checked == pS and f[5].checked == pS and f[6].checked == pS) or
		(f[7].checked == pS and f[8].checked == pS and f[9].checked == pS) or
		(f[1].checked == pS and f[4].checked == pS and f[7].checked == pS) or
		(f[2].checked == pS and f[5].checked == pS and f[8].checked == pS) or
		(f[3].checked == pS and f[6].checked == pS and f[9].checked == pS) or
		(f[1].checked == pS and f[5].checked == pS and f[9].checked == pS) or
		(f[3].checked == pS and f[5].checked == pS and f[7].checked == pS)) then

		outputChatBox('Wygrałeś '..self.players[2].name..' przegrał!', 1);

		self.players[1].wins = self.players[1].wins + 1;
		self.winnerCombination = self:getWinnerCombination();
		self:newRound();
	elseif ((f[1].checked == p2S and f[2].checked == p2S and f[3].checked == p2S) or
		(f[4].checked == p2S and f[5].checked == p2S and f[6].checked == p2S) or
		(f[7].checked == p2S and f[8].checked == p2S and f[9].checked == p2S) or
		(f[1].checked == p2S and f[4].checked == p2S and f[7].checked == p2S) or
		(f[2].checked == p2S and f[5].checked == p2S and f[8].checked == p2S) or
		(f[3].checked == p2S and f[6].checked == p2S and f[9].checked == p2S) or
		(f[1].checked == p2S and f[5].checked == p2S and f[9].checked == p2S) or
		(f[3].checked == p2S and f[5].checked == p2S and f[7].checked == p2S)) then

		outputChatBox('Przegrałeś, '..self.players[2].name..' wygrał!');

		self.players[2].wins = self.players[2].wins + 1;
		self.winnerCombination = self:getWinnerCombination();
		self:newRound();
	else
		-- continue
		self.turn = self.turn - 1 == 1 and 1 or 2;
		self:changeTurn();
	end
end

function tc:changeTurn()
	if (localPlayer ~= self.players[2].data) then
		if (self.turn == 1) then
			triggerServerEvent('infoAboutTurn', self.players[2].data, 'move');
		elseif (self.turn == 2) then
			triggerServerEvent('infoAboutTurn', self.players[2].data, 'wait');
		end
	end
end

function tc:click(b,s)
	if (b == 'left' and s == 'down') then
		for k,v in pairs(self.fields) do
			if (isMouseInPosition(v.x, v.y, rend['board'][3], rend['board'][4]) and not self.tick) and self.turn == 1 then
				if (not v.checked) then
					self:setFieldStatus(k, self.turn == 1 and self.players[1].symbol or self.players[2].symbol);
					triggerServerEvent('syncSymbols', localPlayer, self.players[2].data, k);
				end
				break;
			end
		end
	end
end

function tc:render()
	if (self.tick) then
		local id = self.sToDraw;
		local time = (getTickCount() - self.tick) / 700;

		self.symbols[id].w, self.symbols[id].h = interpolateBetween(0,0,0, rend['board'][3], rend['board'][4], 0, time, 'Linear');
	
		if (time > 1) then
			self.tick = false;
			self.sToDraw = 0;
		end
	end

	dxDrawRectangle(posX, posY, rend['board'][5], rend['board'][6], 0x96FF0022, false);

	local width = dxGetTextWidth(self.players[2].name, 1.2, 'default-bold');

	dxDrawText(self.players[1].name, posX + rend['text']['player'][1], posY + rend['text']['player'][2], 0, 0, 0xFFFFFFFF, 1.2, 'default-bold');
	dxDrawText(self.players[2].name, posX - width - rend['text']['player'][1] + rend['board'][6], posY + rend['text']['player'][2], 0,0, 0xFFFFFFFF, 1.2, 'default-bold');

	dxDrawText(self.result, posX , posY + rend['text']['player'][2], posX + rend['board'][6], 0, 0xFFFFFFFF, 1.2, 'default-bold', 'center');

	for i = 1, #self.fields do
		dxDrawRectangle(self.fields[i].x, self.fields[i].y, rend['board'][3], rend['board'][4], 0xFFFFFFFF, false);
	end

	for k = 1, #self.symbols do
		dxDrawImage(self.symbols[k].x, self.symbols[k].y, self.symbols[k].w, self.symbols[k].h, tex[self.symbols[k].i], 0,0,0, 0xFFFFFFFF, false);
	end

	if (self.gameState == 2) then
		local sf,ef = self.winnerCombination[1].startField, self.winnerCombination[1].endField;

		if (sf == 1 and ef == 9) then
			dxDrawLine(self.fields[sf].x, self.fields[sf].y, self.fields[ef].ex, self.fields[ef].ey, 0xFFFF0000, lineWidth, false);
		elseif (sf == 3 and ef == 7) then
			dxDrawLine(self.fields[sf].x, self.fields[sf].y + rend['board'][4], self.fields[ef].ex, self.fields[ef].ey - rend['board'][4], 0xFFFF0000, lineWidth, false);
		elseif (sf == 1 and ef == 3) or (sf == 4 and ef == 6) or (sf == 7 and ef == 9) then
			dxDrawLine(self.fields[sf].x + rend['board'][3] / 2, self.fields[sf].y, self.fields[ef].ex - rend['board'][3] / 2, self.fields[ef].ey, 0xFFFF0000, lineWidth, false);
		elseif (sf == 1 and ef == 7) or (sf == 2 and ef == 8) or (sf == 3 and ef == 9) then
			dxDrawLine(self.fields[sf].x, self.fields[sf].y + rend['board'][4] / 2, self.fields[ef].ex, self.fields[ef].ey - rend['board'][4] / 2, 0xFFFF0000, lineWidth, false);
		end
	end
end

addEvent('myTurn', true);
addEventHandler('myTurn', localPlayer, function()
	local self = tc;

	self.turn = 1;
end);

addEvent('updateSymbols', true);
addEventHandler('updateSymbols', localPlayer, function(k)
	local self = tc;

	self:setFieldStatus(k, self.players[1].symbol == 'X' and 'O' or 'X');
end);

addEvent('updateGameC', true);
addEventHandler('updateGameC', localPlayer, function(sm)
	local self = tc;

	self.turn = 2;
	self.players[1].symbol = sm;

	if (sm == 'X') then
		self.players[2].symbol = 'O';
	else
		self.players[2].symbol = 'X';
	end
end);

addEvent('startGame', true);
addEventHandler('startGame', localPlayer, function(opponent, starter)
	if not tct then
		tct = tc();
	end

	tct:newGame();
	tct:insertPlayer(localPlayer, not starter and 'O' or 'X', starter);
	tct:insertPlayer(opponent, not starter and 'X' or 'O', starter);

	if (not starter) then
		local self = tc;

		self.turn = 2;
	end
end);

function isMouseInPosition ( x, y, width, height )
	if ( not isCursorShowing( ) ) then
		return false
	end
    local sx, sy = guiGetScreenSize ( )
    local cx, cy = getCursorPosition ( )
    local cx, cy = ( cx * sx ), ( cy * sy )
    if ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) then
        return true
    else
        return false
    end
end

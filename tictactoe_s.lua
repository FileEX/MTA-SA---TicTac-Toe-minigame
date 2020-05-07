--[[
	Author: FileEX
	Tests: Pazdam
]]

addEvent('infoAboutTurn', true);
addEventHandler('infoAboutTurn', root, function(turnType)

	if (turnType == 'wait') then
		outputChatBox('Oczekuj na swoją kolej, ruch przeciwnika!', client);
	elseif (turnType == 'move') then
		outputChatBox('Twoja kolej!', client);
		triggerClientEvent(client, 'myTurn', client);
	end
end);

addEvent('opponentsWin', true);
addEventHandler('opponentsWin', root, function(loser, lose)
	if (lose) then
		outputChatBox('Przegrałeś, '..loser..' wygrał!', client);
	else
		outputChatBox('Wygrałeś, '..loser..' przegrał!', client);
	end
end);

addEvent('syncSymbols', true);
addEventHandler('syncSymbols', root, function(op, i)
	triggerClientEvent(op, 'updateSymbols', op, i);
end);

addEvent('updateData', true);
addEventHandler('updateData', root, function(symbol)
	triggerClientEvent(client, 'updateGameC', client, symbol);
end);

addCommandHandler('tc', function(plr, cmd, t)
	if (t) then
		local pl = getPlayerFromName(t);
		if (pl) then
			if (pl ~= plr) then
				triggerClientEvent(plr, 'startGame', plr,pl, true);

				triggerClientEvent(pl, 'startGame', pl, plr, nil);

				outputChatBox('Wyzwales gracza '..getPlayerName(pl)..' na pojedynek!', plr);
				outputChatBox('Gracz '..getPlayerName(plr)..' wyzywa Cię na pojedynek!', pl);
			else
				outputChatBox('Nie możesz grać sam ze sobą.',plr);
			end
		else
			outputChatBox('Nie znaleziono takiego gracza.',plr);
		end
	end
end);
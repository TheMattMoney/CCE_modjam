local stageX=-300
local stageY=50
local stageSize=2

function onCreate()
	-- background shit
	makeLuaSprite('bg', 'topazbg_temp', stageX, stageY);
	setScrollFactor('bg', 1, 1);
	scaleObject('bg', stageSize, stageSize);
	addLuaSprite('bg', false);
	
	close(true);
end


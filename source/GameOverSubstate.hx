package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;
	var crystallizer:FlxSprite;
	var gobigText:FlxSprite;

	var deathTimer:FlxTimer;

	var stageSuffix:String = "";

	public static var characterName:String = 'gameoverCC';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'gameoverCC';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		loadCrystallizer();

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		Conductor.changeBPM(100);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		//new FlxTimer().start(1.29, playAnims(), 1);

		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			FlxG.sound.play(Paths.sound(deathSoundName));
		});

	}

	public function loadCrystallizer()
	{
		crystallizer = new FlxSprite(0,0);
		crystallizer.frames = Paths.getSparrowAtlas('Crystalising');
		crystallizer.animation.addByPrefix("fillScreen","Crystalising", 24, false, false, false);
		crystallizer.alpha = 0.001;
		crystallizer.scrollFactor.set(0, 0);
		crystallizer.screenCenter();
		add(crystallizer);

		gobigText = new FlxSprite(0,0);
		gobigText.frames = Paths.getSparrowAtlas('DeathText');
		gobigText.animation.addByPrefix("firstPlay","DeathFadeFull", 24, false, false, false);
		gobigText.animation.addByPrefix("singleFrameLoop","static", 24, true, false, false);
		gobigText.animation.addByPrefix("pressRetry","RetryConfirm", 24, false, false, false);
		gobigText.alpha = 0.001;
		gobigText.scrollFactor.set(0, 0);
		gobigText.screenCenter();
		add(gobigText);
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new MainMenuState());
			else
				MusicBeatState.switchState(new MainMenuState());

			FlxG.sound.playMusic(Paths.music('crystalMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath' && !playingDeathSound)
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				coolStartDeath();
				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		playingDeathSound = true;
		deathTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			crystallizer.animation.play('fillScreen');
			crystallizer.alpha = 1;
			FlxG.sound.playMusic(Paths.music(loopSoundName), volume);

			deathTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				gobigText.animation.play('firstPlay');
				gobigText.alpha = 1;
			});
		});
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			deathTimer.cancel();
			crystallizer.alpha = 1;
			crystallizer.animation.play('fillScreen', false, 15);
			gobigText.alpha = 1;
			gobigText.animation.play('pressRetry', true);
			gobigText.screenCenter();
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(1.125, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}

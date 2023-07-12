package sprites;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.math.FlxVelocity;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;

/**
	An edit of FlxEmitter where there isn't a max size, meaning there can be any amount of particles.
	I made this just for the title screen lol.
**/
class InfiniteEmitter extends FlxEmitter
{
	var particleGraphic:FlxGraphicAsset;
	var particleBakedRotationAngles:Int = 0;
	var multipleParticles:Bool = false;
	var autoBuffer:Bool = false;
	var particleTotalFrames:Int = 0;
	
	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);
	}
	
	override function destroy()
	{
		super.destroy();
		particleGraphic = null;
	}
	
	override public function loadParticles(Graphics:FlxGraphicAsset, Quantity:Int = 50, bakedRotationAngles:Int = 16, Multiple:Bool = false,
			AutoBuffer:Bool = false)
	{
		particleGraphic = Graphics;
		particleBakedRotationAngles = bakedRotationAngles;
		multipleParticles = Multiple;
		autoBuffer = AutoBuffer;
		
		var totalFrames:Int = 1;
		
		if (Multiple)
		{
			var sprite = new FlxSprite();
			sprite.loadGraphic(Graphics, true);
			totalFrames = sprite.numFrames;
			sprite.destroy();
		}
		
		particleTotalFrames = totalFrames;
		
		for (i in 0...Quantity)
			add(loadParticle(Graphics, Quantity, bakedRotationAngles, Multiple, AutoBuffer, totalFrames));
			
		return this;
	}
	
	override public function makeParticles(Width:Int = 2, Height:Int = 2, Color:FlxColor = FlxColor.WHITE, Quantity:Int = 50)
	{
		var graph = FlxG.bitmap.create(Width, Height, Color);
		particleGraphic = graph;
		particleBakedRotationAngles = 0;
		multipleParticles = false;
		autoBuffer = false;
		particleTotalFrames = 1;
		
		for (i in 0...Quantity)
		{
			var particle = Type.createInstance(particleClass, []);
			particle.loadGraphic(graph);
			add(particle);
		}
		
		return this;
	}
	
	override public function emitParticle()
	{
		var particle = recycle(cast particleClass, makeParticle);
		
		particle.reset(0, 0); // Position is set later, after size has been calculated
		
		particle.blend = blend;
		particle.immovable = immovable;
		particle.solid = solid;
		particle.allowCollisions = allowCollisions;
		particle.autoUpdateHitbox = autoUpdateHitbox;
		
		// Particle lifespan settings
		if (lifespan.active)
		{
			particle.lifespan = FlxG.random.float(lifespan.min, lifespan.max);
		}
		
		if (velocity.active)
		{
			// Particle velocity/launch angle settings
			particle.velocityRange.active = particle.lifespan > 0 && !particle.velocityRange.start.equals(particle.velocityRange.end);
			
			if (launchMode == FlxEmitterMode.CIRCLE)
			{
				var particleAngle:Float = 0;
				if (launchAngle.active)
					particleAngle = FlxG.random.float(launchAngle.min, launchAngle.max);
					
				// Calculate launch velocity
				_point = FlxVelocity.velocityFromAngle(particleAngle, FlxG.random.float(speed.start.min, speed.start.max));
				particle.velocity.x = _point.x;
				particle.velocity.y = _point.y;
				particle.velocityRange.start.set(_point.x, _point.y);
				
				// Calculate final velocity
				_point = FlxVelocity.velocityFromAngle(particleAngle, FlxG.random.float(speed.end.min, speed.end.max));
				particle.velocityRange.end.set(_point.x, _point.y);
			}
			else
			{
				particle.velocityRange.start.x = FlxG.random.float(velocity.start.min.x, velocity.start.max.x);
				particle.velocityRange.start.y = FlxG.random.float(velocity.start.min.y, velocity.start.max.y);
				particle.velocityRange.end.x = FlxG.random.float(velocity.end.min.x, velocity.end.max.x);
				particle.velocityRange.end.y = FlxG.random.float(velocity.end.min.y, velocity.end.max.y);
				particle.velocity.x = particle.velocityRange.start.x;
				particle.velocity.y = particle.velocityRange.start.y;
			}
		}
		else
			particle.velocityRange.active = false;
			
		// Particle angular velocity settings
		particle.angularVelocityRange.active = particle.lifespan > 0 && angularVelocity.start != angularVelocity.end;
		
		if (!ignoreAngularVelocity)
		{
			if (angularAcceleration.active)
				particle.angularAcceleration = FlxG.random.float(angularAcceleration.start.min, angularAcceleration.start.max);
				
			if (angularVelocity.active)
			{
				particle.angularVelocityRange.start = FlxG.random.float(angularVelocity.start.min, angularVelocity.start.max);
				particle.angularVelocityRange.end = FlxG.random.float(angularVelocity.end.min, angularVelocity.end.max);
				particle.angularVelocity = particle.angularVelocityRange.start;
			}
			
			if (angularDrag.active)
				particle.angularDrag = FlxG.random.float(angularDrag.start.min, angularDrag.start.max);
		}
		else if (angularVelocity.active)
		{
			particle.angularVelocity = (FlxG.random.float(angle.end.min,
				angle.end.max) - FlxG.random.float(angle.start.min, angle.start.max)) / FlxG.random.float(lifespan.min, lifespan.max);
			particle.angularVelocityRange.active = false;
		}
		
		// Particle angle settings
		if (angle.active)
			particle.angle = FlxG.random.float(angle.start.min, angle.start.max);
			
		// Particle scale settings
		if (scale.active)
		{
			particle.scaleRange.start.x = FlxG.random.float(scale.start.min.x, scale.start.max.x);
			particle.scaleRange.start.y = keepScaleRatio ? particle.scaleRange.start.x : FlxG.random.float(scale.start.min.y, scale.start.max.y);
			particle.scaleRange.end.x = FlxG.random.float(scale.end.min.x, scale.end.max.x);
			particle.scaleRange.end.y = keepScaleRatio ? particle.scaleRange.end.x : FlxG.random.float(scale.end.min.y, scale.end.max.y);
			particle.scaleRange.active = particle.lifespan > 0 && !particle.scaleRange.start.equals(particle.scaleRange.end);
			particle.scale.set(particle.scaleRange.start.x, particle.scaleRange.start.y);
			if (particle.autoUpdateHitbox)
				particle.updateHitbox();
		}
		else
			particle.scaleRange.active = false;
			
		// Particle alpha settings
		if (alpha.active)
		{
			particle.alphaRange.start = FlxG.random.float(alpha.start.min, alpha.start.max);
			particle.alphaRange.end = FlxG.random.float(alpha.end.min, alpha.end.max);
			particle.alphaRange.active = particle.lifespan > 0 && particle.alphaRange.start != particle.alphaRange.end;
			particle.alpha = particle.alphaRange.start;
		}
		else
			particle.alphaRange.active = false;
			
		// Particle color settings
		if (color.active)
		{
			particle.colorRange.start = FlxG.random.color(color.start.min, color.start.max);
			particle.colorRange.end = FlxG.random.color(color.end.min, color.end.max);
			particle.colorRange.active = particle.lifespan > 0 && particle.colorRange.start != particle.colorRange.end;
			particle.color = particle.colorRange.start;
		}
		else
			particle.colorRange.active = false;
			
		// Particle drag settings
		if (drag.active)
		{
			particle.dragRange.start.x = FlxG.random.float(drag.start.min.x, drag.start.max.x);
			particle.dragRange.start.y = FlxG.random.float(drag.start.min.y, drag.start.max.y);
			particle.dragRange.end.x = FlxG.random.float(drag.end.min.x, drag.end.max.x);
			particle.dragRange.end.y = FlxG.random.float(drag.end.min.y, drag.end.max.y);
			particle.dragRange.active = particle.lifespan > 0 && !particle.dragRange.start.equals(particle.dragRange.end);
			particle.drag.x = particle.dragRange.start.x;
			particle.drag.y = particle.dragRange.start.y;
		}
		else
			particle.dragRange.active = false;
			
		// Particle acceleration settings
		if (acceleration.active)
		{
			particle.accelerationRange.start.x = FlxG.random.float(acceleration.start.min.x, acceleration.start.max.x);
			particle.accelerationRange.start.y = FlxG.random.float(acceleration.start.min.y, acceleration.start.max.y);
			particle.accelerationRange.end.x = FlxG.random.float(acceleration.end.min.x, acceleration.end.max.x);
			particle.accelerationRange.end.y = FlxG.random.float(acceleration.end.min.y, acceleration.end.max.y);
			particle.accelerationRange.active = particle.lifespan > 0
				&& !particle.accelerationRange.start.equals(particle.accelerationRange.end);
			particle.acceleration.x = particle.accelerationRange.start.x;
			particle.acceleration.y = particle.accelerationRange.start.y;
		}
		else
			particle.accelerationRange.active = false;
			
		// Particle elasticity settings
		if (elasticity.active)
		{
			particle.elasticityRange.start = FlxG.random.float(elasticity.start.min, elasticity.start.max);
			particle.elasticityRange.end = FlxG.random.float(elasticity.end.min, elasticity.end.max);
			particle.elasticityRange.active = particle.lifespan > 0 && particle.elasticityRange.start != particle.elasticityRange.end;
			particle.elasticity = particle.elasticityRange.start;
		}
		else
			particle.elasticityRange.active = false;
			
		// Set position
		particle.x = FlxG.random.float(x, x + width) - particle.width / 2;
		particle.y = FlxG.random.float(y, y + height) - particle.height / 2;
		
		// Restart animation
		if (particle.animation.curAnim != null)
			particle.animation.curAnim.restart();
			
		particle.onEmit();
		
		return particle;
	}
	
	function makeParticle()
	{
		var frame = multipleParticles ? FlxG.random.int(0, particleTotalFrames - 1) : -1;
		
		var particle = new FlxParticle();
		if (FlxG.renderBlit && particleBakedRotationAngles > 0)
			particle.loadRotatedGraphic(particleGraphic, particleBakedRotationAngles, frame, false, autoBuffer);
		else
			particle.loadGraphic(particleGraphic, multipleParticles);
			
		if (multipleParticles)
			particle.animation.frameIndex = frame;
			
		return particle;
	}
}

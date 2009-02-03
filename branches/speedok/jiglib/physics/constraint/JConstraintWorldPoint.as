/*
Copyright (c) 2007 Danny Chapman 
http://www.rowlhouse.co.uk

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.
3. This notice may not be removed or altered from any source
distribution.
*/

/**
* @author Muzer(muzerly@gmail.com)
* @link http://code.google.com/p/jiglibflash
*/


package jiglib.physics.constraint {

	import jiglib.math.*;
	import jiglib.physics.RigidBody;
	
	public class JConstraintWorldPoint extends JConstraint {
		
		private const minVelForProcessing:Number = 0.001;
		private const allowedDeviation:Number = 0.01;
		private const timescale:Number = 4;
		
		private var _body:RigidBody;
		private var _pointOnBody:JNumber3D;
		private var _worldPosition:JNumber3D;
		
		public function JConstraintWorldPoint(body:RigidBody, pointOnBody:JNumber3D, worldPosition:JNumber3D) {
			_body = body;
			_pointOnBody = pointOnBody;
			_worldPosition = worldPosition;
		}
		
		public function set WorldPosition(pos:JNumber3D):void
		{
			_worldPosition = pos;
		}
		public function get WorldPosition():JNumber3D
		{
			return _worldPosition;
		}
		
		override public function Apply(dt:Number):Boolean {
			this.Satisfied = true;
			
			var worldPos:JNumber3D = _pointOnBody.clone();
			JMatrix3D.multiplyVector(_body.CurrentState.Orientation, worldPos);
			worldPos = JNumber3D.add(worldPos, _body.CurrentState.Position);
			var R:JNumber3D = JNumber3D.sub(worldPos, _body.CurrentState.Position);
			var currentVel:JNumber3D = JNumber3D.add(_body.CurrentState.LinVelocity, JNumber3D.cross(R, _body.CurrentState.RotVelocity));
			
			var desiredVel:JNumber3D;
			var deviationDir:JNumber3D;
			var deviation:JNumber3D = JNumber3D.sub(worldPos, _worldPosition);
			var deviationDistance:Number = deviation.modulo;
			if (deviationDistance > allowedDeviation)
			{
				deviationDir = JNumber3D.divide(deviation, deviationDistance);
				desiredVel = JNumber3D.multiply(deviationDir, (allowedDeviation - deviationDistance) / (timescale * dt));
			}
			else
			{
				desiredVel = JNumber3D.ZERO;
			}
			
			var N:JNumber3D = JNumber3D.sub(currentVel, desiredVel);
			var normalVel:Number = N.modulo;
			if (normalVel < minVelForProcessing)
			{
				return false;
			}
			N = JNumber3D.divide(N, normalVel);
			
			var tempV:JNumber3D = JNumber3D.cross(N, R);
			JMatrix3D.multiplyVector(_body.WorldInvInertia, tempV);
			var denominator:Number = _body.InvMass + JNumber3D.dot(N, JNumber3D.cross(R, tempV));
			
			if (denominator < JNumber3D.NUM_TINY)
			{
				return false;
			}
			
			var normalImpulse:Number = -normalVel / denominator;
			
			_body.ApplyWorldImpulse(JNumber3D.multiply(N, normalImpulse), worldPos);
			
			_body.SetConstraintsAndCollisionsUnsatisfied();
			this.Satisfied = true;
			
			return true;
		}
		
	}
	
}

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
	
	public class JConstraintPoint extends JConstraint {
		
		private const _maxVelMag:Number = 20;
        private const _minVelForProcessing:Number = 0.01;
		
		
		private var _body0:RigidBody;
		private var _body1:RigidBody;
		private var _body0Pos:JNumber3D;
		private var _body1Pos:JNumber3D;
		
		private var _timescale:Number;
		private var _allowedDistance:Number;
		
		private var R0:JNumber3D;
		private var R1:JNumber3D;
		private var _worldPos:JNumber3D;
		private var _vrExtra:JNumber3D;
		
		public function JConstraintPoint(body0:RigidBody, body0Pos:JNumber3D, body1:RigidBody, body1Pos:JNumber3D, allowedDistance:Number = 1, timescale:Number = 1) {
			_body0 = body0;
			_body0Pos = body0Pos;
			_body1 = body1;
			_body1Pos = body1Pos;
			_allowedDistance = allowedDistance;
			_timescale = timescale;
			if (_timescale < JNumber3D.NUM_TINY)
			{
				_timescale = JNumber3D.NUM_TINY;
			}
		}
		
		override public function PreApply(dt:Number):void{
			this.Satisfied = false;
			
			R0 = _body0Pos.clone();
			JMatrix3D.multiplyVector(_body0.CurrentState.Orientation, R0);
			R1 = _body1Pos.clone();
			JMatrix3D.multiplyVector(_body1.CurrentState.Orientation, R1);
			
			var worldPos0:JNumber3D = JNumber3D.add(_body0.CurrentState.Position, R0);
			var worldPos1:JNumber3D = JNumber3D.add(_body1.CurrentState.Position, R1);
			_worldPos = JNumber3D.multiply(JNumber3D.add(worldPos0, worldPos1), 0.5);
			
			var deviation:JNumber3D = JNumber3D.sub(worldPos0, worldPos1);
			var deviationAmount:Number = deviation.modulo;
			if (deviationAmount > _allowedDistance)
			{
				_vrExtra = JNumber3D.multiply(deviation, (deviationAmount - _allowedDistance) / (deviationAmount * Math.max(_timescale, dt)));
			}
			else
			{
				_vrExtra = JNumber3D.ZERO;
			}
		}
		
		override public function Apply(dt:Number):Boolean{
			this.Satisfied = true;
			
			if (!_body0.IsActive() && !_body0.IsActive())
			{
				return false;
			}
			
			var currentVel0:JNumber3D = _body0.GetVelocity(R0);
			var currentVel1:JNumber3D = _body1.GetVelocity(R1);
			var Vr:JNumber3D = JNumber3D.add(_vrExtra, JNumber3D.sub(currentVel0, currentVel1));
			
			var normalVel:Number = Vr.modulo;
			if (normalVel < _minVelForProcessing)
			{
				return false;
			}
			
			if (normalVel > _maxVelMag)
			{
				Vr = JNumber3D.multiply(Vr, _maxVelMag / normalVel);
				normalVel = _maxVelMag;
			}
			
			var N:JNumber3D = JNumber3D.divide(Vr, normalVel);
			var tempVec1:JNumber3D = JNumber3D.cross(N, R0);
			JMatrix3D.multiplyVector(_body0.WorldInvInertia, tempVec1);
			var tempVec2:JNumber3D = JNumber3D.cross(N, R1);
			JMatrix3D.multiplyVector(_body1.WorldInvInertia, tempVec2);
			var denominator:Number = _body0.InvMass + _body1.InvMass + JNumber3D.dot(N, JNumber3D.cross(R0, tempVec1)) + JNumber3D.dot(N, JNumber3D.cross(R1, tempVec2));
			if (denominator < JNumber3D.NUM_TINY)
			{
				return false;
			}
			 
			var normalImpulse:JNumber3D = JNumber3D.multiply(N, -normalVel / denominator);
			_body0.ApplyWorldImpulse(normalImpulse, _worldPos);
			_body1.ApplyWorldImpulse(JNumber3D.multiply(normalImpulse, -1), _worldPos);
			 
			_body0.SetConstraintsAndCollisionsUnsatisfied();
			_body1.SetConstraintsAndCollisionsUnsatisfied();
			this.Satisfied = true;
			return true;
		}
		
	}
	
}

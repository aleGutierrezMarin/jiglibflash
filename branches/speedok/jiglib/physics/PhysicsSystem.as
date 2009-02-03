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

package jiglib.physics {

	import jiglib.collision.*;
	import jiglib.math.*;
	import jiglib.cof.JConfig;
	import jiglib.physics.constraint.*;
	
	import flash.utils.getTimer;
	
	public class PhysicsSystem {
		
		private static var _currentPhysicsSystem:PhysicsSystem;
		
		private const _maxVelMag:Number = 0.5;
        private const _minVelForProcessing:Number = 0.001;
		
		
		private var _bodies:Array;
		private var _activeBodies:Array;
		private var _collisions:Array;
		private var _constraints:Array;
		 
		 
		private var _gravityAxis:int;
		private var _gravity:JNumber3D;
		
		private var _doingIntegration:Boolean;
		
		private var DetectAllCollisionsFn:Function;
		private var PreProcessCollisionFn:Function;
		private var PreProcessContactFn:Function;
		private var ProcessCollisionFn:Function;
		private var ProcessContactFn:Function;
		
		private var _cachedContacts:Array;
		private var _collisionSystem:CollisionSystem;
		
		
		public static function getInstance():PhysicsSystem
	    {
	    	if (!_currentPhysicsSystem) {
				trace("version: JigLibFlash v0.28 (2009-2-1)");
			    _currentPhysicsSystem = new PhysicsSystem();
		    }
		    return _currentPhysicsSystem;
	    }
		
		public function PhysicsSystem() {
			
			SetSolverType(JConfig.solverType);
			SetDetectCollisionsType(JConfig.detectCollisionsType);
			_doingIntegration = false;
			_bodies = new Array();
			_collisions = new Array();
			_activeBodies = new Array();
			_constraints = new Array();
			
			_cachedContacts = new Array();
			_collisionSystem = new CollisionSystem();
			
			SetGravity(JNumber3D.multiply(JNumber3D.UP, -10));
		}
		 
		private function GetAllExternalForces(dt:Number):void
		{
			for (var i:String in _bodies)
			{
				_bodies[i].AddExternalForces(dt);
			}
		}
		
		public function GetCollisionSystem():CollisionSystem
		{
			return _collisionSystem;
		}
		 
		public function SetGravity(gravity:JNumber3D):void
		{
			_gravity = gravity;
			if (_gravity.x == _gravity.y && _gravity.y == _gravity.z)
			{
				_gravityAxis = -1;
			}
			_gravityAxis = 0;
			if (Math.abs(_gravity.y) > Math.abs(_gravity.z))
			{
				_gravityAxis = 1;
			}
			if (Math.abs(_gravity.z) > Math.abs(_gravity.toArray()[_gravityAxis]))
			{
				_gravityAxis = 2;
			}
		}
		public function get Gravity():JNumber3D
		{
			return _gravity;
		}
		public function get GravityAxis():int
		{
			return _gravityAxis;
		}
		
		public function get Bodys():Array
		{
			return _bodies;
		}
		
		public function AddBody(body:RigidBody):void
		{
			if (!findBody(body))
			{
			    _bodies.push(body);
				_collisionSystem.AddCollisionBody(body);
			}
		}
		public function RemoveBody(body:RigidBody):void
		{
			if (findBody(body))
			{
			    _bodies.splice(_bodies.indexOf(body), 1);
				_collisionSystem.RemoveCollisionBody(body);
			}
		}
		
		public function AddConstraint(constraint:JConstraint):void
		{
			if (!findConstraint(constraint))
			{
			    _constraints.push(constraint);
			}
		}
		public function RemoveConstraint(constraint:JConstraint):void
		{
			if (findConstraint(constraint))
			{
			    _constraints.splice(_constraints.indexOf(constraint), 1);
			}
		}
		
		public function SetSolverType(type:String):void
		{
			switch(type)
			{
				case "FAST":
				    PreProcessCollisionFn=PreProcessCollisionFast;
					PreProcessContactFn=PreProcessCollisionFast;
					ProcessCollisionFn=ProcessCollision;
					ProcessContactFn=ProcessCollision;
				    return;
				case "NORMAL":
				    PreProcessCollisionFn=PreProcessCollisionNormal;
					PreProcessContactFn=PreProcessCollisionNormal;
					ProcessCollisionFn=ProcessCollision;
					ProcessContactFn=ProcessCollision;
					return;
				case "ACCUMULATED":
					PreProcessCollisionFn=PreProcessCollisionNormal;
					PreProcessContactFn=PreProcessCollisionAccumulated;
					ProcessCollisionFn=ProcessCollision;
					ProcessContactFn=ProcessCollisionAccumulated;
				    return;
				default:
					PreProcessCollisionFn = PreProcessCollisionNormal;
					PreProcessContactFn = PreProcessCollisionNormal;
					ProcessCollisionFn = ProcessCollision;
					ProcessContactFn = ProcessCollision;
					return;
			}
		}
		public function SetDetectCollisionsType(type:String):void
		{
			switch(type)
			{
				case "DIRECT":
				    DetectAllCollisionsFn=DetectAllCollisionsDirect;
					return;
				case "STORE":
				    DetectAllCollisionsFn=DetectAllCollisionsStore;
					return;
				default:
					DetectAllCollisionsFn=DetectAllCollisionsDirect;
					return;
			}
		}
		 
		private function findBody(body:RigidBody):Boolean
		{
			for (var i:String in _bodies)
			{
				if (body == _bodies[i])
				{
					return true;
				}
			}
			return false;
		}
		private function findConstraint(constraint:JConstraint):Boolean
		{
			for (var i:String in _constraints)
			{
				if (constraint == _constraints[i])
				{
					return true;
				}
			}
			return false;
		}
		
		private function PreProcessCollisionFast(collision:CollisionInfo, dt:Number):void
		{
			collision.Satisfied = false;
			
			var body0:RigidBody=collision.ObjInfo.body0;
			var body1:RigidBody=collision.ObjInfo.body1;
			
			var N:JNumber3D=collision.DirToBody;
			var timescale:Number = JConfig.numPenetrationRelaxationTimesteps * dt;
			var approachScale:Number;
			var ptInfo:CollPointInfo;
			var tempV:JNumber3D;
			var ptNum:Number = Number(collision.PointInfo.length);
			
			if (ptNum > 1)
			{
				var avR0:JNumber3D = new JNumber3D();
				var avR1:JNumber3D = new JNumber3D();
				var avDepth:Number = 0;
				
				for(var i:uint=0; i<ptNum; i++)
				{
					ptInfo=collision.PointInfo[i];
					avR0 = JNumber3D.add(avR0, ptInfo.R0);
					avR1 = JNumber3D.add(avR1, ptInfo.R1);
					avDepth += ptInfo.InitialPenetration;
				}
				avR0 = JNumber3D.divide(avR0, ptNum);
				avR1 = JNumber3D.divide(avR1, ptNum);
				avDepth /= ptNum;
				 
				collision.PointInfo = new Array();
				collision.PointInfo[0] = new CollPointInfo();
				collision.PointInfo[0].R0 = avR0;
				collision.PointInfo[0].R1 = avR1;
				collision.PointInfo[0].InitialPenetration = avDepth;
			}
			 
			for(i=0; i<collision.PointInfo.length; i++)
			{
				ptInfo=collision.PointInfo[i];
				if(!body0.Getmovable())
				{
					ptInfo.Denominator=0;
				}
				else
				{
					tempV = JNumber3D.cross(N, ptInfo.R0);
					JMatrix3D.multiplyVector(body0.WorldInvInertia, tempV);
					ptInfo.Denominator = body0.InvMass + JNumber3D.dot(N, JNumber3D.cross(ptInfo.R0, tempV));
				}
				if(body1.Getmovable())
				{
					tempV=JNumber3D.cross(N,ptInfo.R1);
					JMatrix3D.multiplyVector(body1.WorldInvInertia,tempV);
					ptInfo.Denominator+=(body1.InvMass+JNumber3D.dot(N,JNumber3D.cross(ptInfo.R1,tempV)));
				}
				if(ptInfo.Denominator<JNumber3D.NUM_TINY)
				{
					ptInfo.Denominator=JNumber3D.NUM_TINY;
				}
				
				if(ptInfo.InitialPenetration>JConfig.allowedPenetration)
				{
					ptInfo.MinSeparationVel=(ptInfo.InitialPenetration - JConfig.allowedPenetration) / timescale;
				}
				else
				{
					approachScale = -0.1 * (ptInfo.InitialPenetration - JConfig.allowedPenetration) / JConfig.allowedPenetration;
					if(approachScale<JNumber3D.NUM_TINY)
					{
						approachScale=JNumber3D.NUM_TINY;
					}
					else if(approachScale>1)
					{
						approachScale=1;
					}
					ptInfo.MinSeparationVel = approachScale * (ptInfo.InitialPenetration - JConfig.allowedPenetration) / Math.max(dt, JNumber3D.NUM_TINY);
				}
				if(ptInfo.MinSeparationVel>_maxVelMag)
				{
					ptInfo.MinSeparationVel=_maxVelMag;
				}
			}
		}
		
		private function PreProcessCollisionNormal(collision:CollisionInfo, dt:Number):void
		{
			collision.Satisfied = false;
			
			var body0:RigidBody=collision.ObjInfo.body0;
			var body1:RigidBody=collision.ObjInfo.body1;
			 
			var N:JNumber3D=collision.DirToBody;
			var timescale:Number = JConfig.numPenetrationRelaxationTimesteps * dt;
			var approachScale:Number;
			var ptInfo:CollPointInfo;
			var tempV:JNumber3D;
			for(var i:uint=0; i<collision.PointInfo.length; i++)
			{
				ptInfo=collision.PointInfo[i];
				if(!body0.Getmovable())
				{
					ptInfo.Denominator=0;
				}
				else
				{
					tempV = JNumber3D.cross(N, ptInfo.R0);
					JMatrix3D.multiplyVector(body0.WorldInvInertia, tempV);
					ptInfo.Denominator = body0.InvMass + JNumber3D.dot(N, JNumber3D.cross(ptInfo.R0, tempV));
				}
				 
				if(body1.Getmovable())
				{
					tempV=JNumber3D.cross(N,ptInfo.R1);
					JMatrix3D.multiplyVector(body1.WorldInvInertia,tempV);
					ptInfo.Denominator+=(body1.InvMass+JNumber3D.dot(N,JNumber3D.cross(ptInfo.R1,tempV)));
				}
				if(ptInfo.Denominator<JNumber3D.NUM_TINY)
				{
					ptInfo.Denominator=JNumber3D.NUM_TINY;
				}
				if(ptInfo.InitialPenetration>JConfig.allowedPenetration)
				{
					ptInfo.MinSeparationVel=(ptInfo.InitialPenetration - JConfig.allowedPenetration) / timescale;
				}
				else
				{
					approachScale = -0.1 * (ptInfo.InitialPenetration - JConfig.allowedPenetration) / JConfig.allowedPenetration;
					if(approachScale<JNumber3D.NUM_TINY)
					{
						approachScale=JNumber3D.NUM_TINY;
					}
					else if(approachScale>1)
					{
						approachScale=1;
					}
					ptInfo.MinSeparationVel = approachScale * (ptInfo.InitialPenetration - JConfig.allowedPenetration) / Math.max(dt, JNumber3D.NUM_TINY);
				}
				if(ptInfo.MinSeparationVel>_maxVelMag)
				{
					ptInfo.MinSeparationVel=_maxVelMag;
				}
			}
			
		}
		
		private function PreProcessCollisionAccumulated(collision:CollisionInfo, dt:Number):void
		{
			collision.Satisfied = false;
			var body0:RigidBody = collision.ObjInfo.body0;
			var body1:RigidBody = collision.ObjInfo.body1;
			 
			var N:JNumber3D=collision.DirToBody;
			var timescale:Number = JConfig.numPenetrationRelaxationTimesteps * dt;
			 
			var tempV:JNumber3D;
			var ptInfo:CollPointInfo;
			var approachScale:Number;
			
			for(var i:uint=0; i<collision.PointInfo.length; i++)
			{
				ptInfo = collision.PointInfo[i];
				if(!body0.Getmovable())
				{
					ptInfo.Denominator=0;
				}
				else
				{
					tempV = JNumber3D.cross(N, ptInfo.R0);
					JMatrix3D.multiplyVector(body0.WorldInvInertia, tempV);
					ptInfo.Denominator = body0.InvMass + JNumber3D.dot(N, JNumber3D.cross(ptInfo.R0, tempV));
				}
				 
				if(body1.Getmovable())
				{
					tempV=JNumber3D.cross(N,ptInfo.R1);
					JMatrix3D.multiplyVector(body1.WorldInvInertia,tempV);
					ptInfo.Denominator+=(body1.InvMass+JNumber3D.dot(N,JNumber3D.cross(ptInfo.R1,tempV)));
				}
				if(ptInfo.Denominator<JNumber3D.NUM_TINY)
				{
					ptInfo.Denominator = JNumber3D.NUM_TINY;
				}
				if(ptInfo.InitialPenetration>JConfig.allowedPenetration)
				{
					ptInfo.MinSeparationVel=(ptInfo.InitialPenetration - JConfig.allowedPenetration) / timescale;
				}
				else
				{
					approachScale = -0.1 * (ptInfo.InitialPenetration - JConfig.allowedPenetration) / JConfig.allowedPenetration;
					if(approachScale<JNumber3D.NUM_TINY)
					{
						approachScale = JNumber3D.NUM_TINY;
					}
					else if(approachScale>1)
					{
						approachScale = 1;
					}
					ptInfo.MinSeparationVel = approachScale * (ptInfo.InitialPenetration - JConfig.allowedPenetration) / Math.max(dt, JNumber3D.NUM_TINY);
				}
				 
				ptInfo.AccumulatedNormalImpulse = 0;
				ptInfo.AccumulatedNormalImpulseAux = 0;
				ptInfo.AccumulatedFrictionImpulse = new JNumber3D();
				
				var bestDistSq:Number = 0.04;
				var bp:BodyPair = new BodyPair(body0, body1, JNumber3D.ZERO, JNumber3D.ZERO);
				
				for (var j:String in _cachedContacts)
				{
					if (!(bp.Body0 == _cachedContacts[j].Pair.Body0 && bp.Body1 == _cachedContacts[j].Pair.Body1))
					{
						continue;
					}
					var distSq:Number = (_cachedContacts[j].Pair.Body0 == body0)?
					JNumber3D.sub(_cachedContacts[j].Pair.R, ptInfo.R0).modulo2:
					JNumber3D.sub(_cachedContacts[j].Pair.R, ptInfo.R1).modulo2;
					
					if (distSq < bestDistSq)
					{
						bestDistSq = distSq;
						ptInfo.AccumulatedNormalImpulse = _cachedContacts[j].Impulse.NormalImpulse;
						ptInfo.AccumulatedNormalImpulseAux = _cachedContacts[j].Impulse.NormalImpulseAux;
						ptInfo.AccumulatedFrictionImpulse = _cachedContacts[j].Impulse.FrictionImpulse;
						if (_cachedContacts[j].Pair.Body0 != body0)
						{
							ptInfo.AccumulatedFrictionImpulse = JNumber3D.multiply(ptInfo.AccumulatedFrictionImpulse, -1);
						}
					}
				}
				
				if (ptInfo.AccumulatedNormalImpulse != 0)
				{
					var impulse:JNumber3D = JNumber3D.multiply(N, ptInfo.AccumulatedNormalImpulse);
					impulse = JNumber3D.add(impulse, ptInfo.AccumulatedFrictionImpulse);
					body0.ApplyBodyWorldImpulse(impulse, ptInfo.R0);
				    body1.ApplyBodyWorldImpulse(JNumber3D.multiply(impulse, -1), ptInfo.R1);
				}
				if (ptInfo.AccumulatedNormalImpulseAux != 0)
				{
					impulse = JNumber3D.multiply(N, ptInfo.AccumulatedNormalImpulseAux);
					body0.ApplyBodyWorldImpulseAux(impulse, ptInfo.R0);
				    body1.ApplyBodyWorldImpulseAux(JNumber3D.multiply(impulse, -1), ptInfo.R1);
				}
			}
		}
		
		private function ProcessCollision(collision:CollisionInfo, dt:Number):Boolean
		{
			collision.Satisfied = true;
			
			var body0:RigidBody=collision.ObjInfo.body0;
			var body1:RigidBody=collision.ObjInfo.body1;
			 
			var gotOne:Boolean = false;
			var N:JNumber3D = collision.DirToBody;
			 
			var deltaVel:Number;
			var normalVel:Number;
			var finalNormalVel:Number;
			var normalImpulse:Number;
			var impulse:JNumber3D;
			var Vr0:JNumber3D;
			var Vr1:JNumber3D;
			var ptInfo:CollPointInfo;
			
			for (var i:uint = 0; i < collision.PointInfo.length; i++)
			{
				ptInfo = collision.PointInfo[i];
				
				Vr0 = body0.GetVelocity(ptInfo.R0);
				Vr1 = body1.GetVelocity(ptInfo.R1);
				normalVel = JNumber3D.dot(JNumber3D.sub(Vr0, Vr1), N);
				if (normalVel > ptInfo.MinSeparationVel)
				{
					continue;
				}
				finalNormalVel = -1 * collision.Mat.Restitution * normalVel;
				if (finalNormalVel < _minVelForProcessing)
				{
					finalNormalVel = ptInfo.MinSeparationVel;
				}
				deltaVel = finalNormalVel - normalVel;
				if (deltaVel <= _minVelForProcessing)
				{
				    continue;
				}
				normalImpulse = deltaVel / ptInfo.Denominator;
				
				gotOne = true;
				impulse = JNumber3D.multiply(N, normalImpulse);
				
				body0.ApplyBodyWorldImpulse(impulse, ptInfo.R0);
				body1.ApplyBodyWorldImpulse(JNumber3D.multiply(impulse, -1), ptInfo.R1);
				
				var tempV:JNumber3D;
				var VR:JNumber3D=JNumber3D.sub(Vr0,Vr1);
				var tangent_vel:JNumber3D=JNumber3D.sub(VR,JNumber3D.multiply(N,JNumber3D.dot(VR,N)));
				var tangent_speed:Number=tangent_vel.modulo;
				if(tangent_speed>_minVelForProcessing)
				{
					var T:JNumber3D = JNumber3D.multiply(JNumber3D.divide(tangent_vel, tangent_speed), -1);
					var denominator:Number;
					if(body0.Getmovable())
					{
						tempV=JNumber3D.cross(T,ptInfo.R0);
						JMatrix3D.multiplyVector(body0.WorldInvInertia,tempV);
						denominator = body0.InvMass + JNumber3D.dot(T, JNumber3D.cross(ptInfo.R0, tempV));
					}
					if(body1.Getmovable())
					{
						tempV=JNumber3D.cross(T,ptInfo.R1);
						JMatrix3D.multiplyVector(body1.WorldInvInertia,tempV);
						denominator += (body1.InvMass + JNumber3D.dot(T, JNumber3D.cross(ptInfo.R1, tempV)));
					}
					if (denominator > JNumber3D.NUM_TINY)
					{
						var impulseToReverse:Number = tangent_speed / denominator;
						var impulseFromNormalImpulse:Number = collision.Mat.StaticFriction * normalImpulse;
						
						var frictionImpulse:Number;
						if (impulseToReverse < impulseFromNormalImpulse)
						{
							frictionImpulse = impulseToReverse;
						}
						else
						{
							frictionImpulse = collision.Mat.DynamicFriction * normalImpulse;
						}
						T = JNumber3D.multiply(T, frictionImpulse);
						body0.ApplyBodyWorldImpulse(T, ptInfo.R0);
						body1.ApplyBodyWorldImpulse(JNumber3D.multiply(T, -1), ptInfo.R1);
					}
				}
			}
			if (gotOne)
			{
				body0.SetConstraintsAndCollisionsUnsatisfied();
				body1.SetConstraintsAndCollisionsUnsatisfied();
			}
			return gotOne;
		}
		
		private function ProcessCollisionAccumulated(collision:CollisionInfo, dt:Number):Boolean
		{
			collision.Satisfied = true;
			var gotOne:Boolean = false;
			var N:JNumber3D=collision.DirToBody;
			var body0:RigidBody=collision.ObjInfo.body0;
			var body1:RigidBody=collision.ObjInfo.body1;
			 
			var deltaVel:Number;
			var normalVel:Number;
			var normalImpulse:Number;
			var impulse:JNumber3D;
			var Vr0:JNumber3D;
			var Vr1:JNumber3D;
			var ptInfo:CollPointInfo;
			
			for(var i:uint=0; i<collision.PointInfo.length; i++)
			{
				ptInfo = collision.PointInfo[i];
				 
				Vr0 = body0.GetVelocity(ptInfo.R0);
				Vr1 = body1.GetVelocity(ptInfo.R1);
				normalVel = JNumber3D.dot(JNumber3D.sub(Vr0, Vr1), N);
				 
				deltaVel = -normalVel;
				if (ptInfo.MinSeparationVel < 0)
				{
					deltaVel += ptInfo.MinSeparationVel;
				}
				 
				if (Math.abs(deltaVel) > _minVelForProcessing)
				{
					normalImpulse = deltaVel / ptInfo.Denominator;
					var origAccumulatedNormalImpulse:Number = ptInfo.AccumulatedNormalImpulse;
					ptInfo.AccumulatedNormalImpulse = Math.max(ptInfo.AccumulatedNormalImpulse + normalImpulse, 0);
					var actualImpulse:Number = ptInfo.AccumulatedNormalImpulse - origAccumulatedNormalImpulse;
					
					impulse = JNumber3D.multiply(N, actualImpulse);
					body0.ApplyBodyWorldImpulse(impulse, ptInfo.R0);
				    body1.ApplyBodyWorldImpulse(JNumber3D.multiply(impulse, -1), ptInfo.R1);
					
					gotOne = true;
				}
				
				Vr0 = body0.GetVelocityAux(ptInfo.R0);
				Vr1 = body1.GetVelocityAux(ptInfo.R1);
				normalVel = JNumber3D.dot(JNumber3D.sub(Vr0, Vr1), N);
				 
				deltaVel = -normalVel;
				if (ptInfo.MinSeparationVel > 0)
				{
					deltaVel += ptInfo.MinSeparationVel;
				}
				if (Math.abs(deltaVel) > _minVelForProcessing)
				{
					normalImpulse = deltaVel / ptInfo.Denominator;
					origAccumulatedNormalImpulse = ptInfo.AccumulatedNormalImpulseAux;
					ptInfo.AccumulatedNormalImpulseAux = Math.max(ptInfo.AccumulatedNormalImpulseAux + normalImpulse, 0);
					actualImpulse = ptInfo.AccumulatedNormalImpulseAux - origAccumulatedNormalImpulse;
					
					impulse = JNumber3D.multiply(N, actualImpulse);
					body0.ApplyBodyWorldImpulseAux(impulse, ptInfo.R0);
				    body1.ApplyBodyWorldImpulseAux(JNumber3D.multiply(impulse, -1), ptInfo.R1);
					
					gotOne = true;
				}
				 
				 
				if(ptInfo.AccumulatedNormalImpulse > 0)
				{
					Vr0 = body0.GetVelocity(ptInfo.R0);
				    Vr1 = body1.GetVelocity(ptInfo.R1);
					var tempV:JNumber3D;
				    var VR:JNumber3D = JNumber3D.sub(Vr0, Vr1);
				    var tangent_vel:JNumber3D = JNumber3D.sub(VR, JNumber3D.multiply(N, JNumber3D.dot(VR, N)));
				    var tangent_speed:Number = tangent_vel.modulo;
					if(tangent_speed>_minVelForProcessing)
				    {
					var T:JNumber3D = JNumber3D.multiply(JNumber3D.divide(tangent_vel, tangent_speed), -1);
					var denominator:Number = 0;
					if(body0.Getmovable())
					{
						tempV=JNumber3D.cross(T,ptInfo.R0);
						JMatrix3D.multiplyVector(body0.WorldInvInertia,tempV);
						denominator=body0.InvMass+JNumber3D.dot(T,JNumber3D.cross(ptInfo.R0,tempV));
					}
					if(body1.Getmovable())
					{
						tempV=JNumber3D.cross(T,ptInfo.R1);
						JMatrix3D.multiplyVector(body1.WorldInvInertia, tempV);
						denominator += (body1.InvMass + JNumber3D.dot(T, JNumber3D.cross(ptInfo.R1, tempV)));
					}
					if (denominator > JNumber3D.NUM_TINY)
					{
						var impulseToReverse:Number = tangent_speed / denominator;
						var frictionImpulseVec:JNumber3D = JNumber3D.multiply(T, impulseToReverse);
						
						var origAccumulatedFrictionImpulse:JNumber3D = ptInfo.AccumulatedFrictionImpulse.clone();
						ptInfo.AccumulatedFrictionImpulse = JNumber3D.add(ptInfo.AccumulatedFrictionImpulse, frictionImpulseVec);
						
						var AFIMag:Number = ptInfo.AccumulatedFrictionImpulse.modulo;
						var maxAllowedAFIMag:Number = collision.Mat.StaticFriction * ptInfo.AccumulatedNormalImpulse;
						
						if (AFIMag > JNumber3D.NUM_TINY && AFIMag > maxAllowedAFIMag)
						{
							ptInfo.AccumulatedFrictionImpulse = JNumber3D.multiply(ptInfo.AccumulatedFrictionImpulse, maxAllowedAFIMag / AFIMag);
						}
						
						var actualFrictionImpulse:JNumber3D = JNumber3D.sub(ptInfo.AccumulatedFrictionImpulse, origAccumulatedFrictionImpulse);
						
						body0.ApplyBodyWorldImpulse(actualFrictionImpulse, ptInfo.R0);
						body1.ApplyBodyWorldImpulse(JNumber3D.multiply(actualFrictionImpulse, -1), ptInfo.R1);
					}
				    }
				}
			}
			if (gotOne)
			{
				body0.SetConstraintsAndCollisionsUnsatisfied();
				body1.SetConstraintsAndCollisionsUnsatisfied();
			}
			return gotOne;
		}
		
		private function UpdateContactCache():void
		{
			_cachedContacts=new Array();
			var collInfo:CollisionInfo;
			var ptInfo:CollPointInfo;
			var fricImpulse:JNumber3D;
			var contact:Object;
			for (var i:String in _collisions)
			{
				collInfo = _collisions[i];
				for (var j:String in collInfo.PointInfo)
				{
					ptInfo = collInfo.PointInfo[j];
					fricImpulse = (collInfo.ObjInfo.body0.ID > collInfo.ObjInfo.body1.ID)?
					ptInfo.AccumulatedFrictionImpulse:JNumber3D.multiply(ptInfo.AccumulatedFrictionImpulse, -1);
					 
					contact = new Object();
					contact.Pair = new BodyPair(collInfo.ObjInfo.body0, collInfo.ObjInfo.body1, ptInfo.R0, ptInfo.R1);
					contact.Impulse = new CachedImpulse(ptInfo.AccumulatedNormalImpulse, ptInfo.AccumulatedNormalImpulseAux, ptInfo.AccumulatedFrictionImpulse);
					
					_cachedContacts.push(contact);
				}
			}
		}
		
		private function HandleAllConstraints(dt:Number, iter:int, forceInelastic:Boolean):void
		{
			var origNumCollisions:int = _collisions.length;
			
			for (var k:String in _constraints)
			{
				_constraints[k].PreApply(dt);
			}
			
			if(forceInelastic)
			{
				for(var i:String in _collisions)
				{
					_collisions[i].Mat.Restitution = 0;
					_collisions[i].Satisfied = false;
					PreProcessContactFn(_collisions[i], dt);
				}
			}
			else
			{
				for(i in _collisions)
				{
					PreProcessCollisionFn(_collisions[i],dt);
				}
			}
			
			var flag:Boolean;
			var gotOne:Boolean;
			for (var step:uint = 0; step < iter; step++)
			{
				gotOne = false;
				for(i in _collisions)
				{
					if (!_collisions[i].Satisfied)
					{
						if(forceInelastic)
						{
							flag = ProcessContactFn(_collisions[i], dt);
							gotOne = gotOne || flag;
						}
						else
						{
							flag = ProcessCollisionFn(_collisions[i], dt);
							gotOne = gotOne || flag;
						}
					}
				}
				for (k in _constraints)
				{
					if (!_constraints[k].Satisfied)
					{
						flag = _constraints[k].Apply(dt);
						gotOne = gotOne || flag;
					}
				}
				TryToActivateAllFrozenObjects();
				
				if(forceInelastic)
			    {
			    	for (var j:uint = origNumCollisions; j < _collisions.length; j++)
			    	{
						_collisions[i].Mat.Restitution = 0;
					    _collisions[i].Satisfied = false;
			    		PreProcessContactFn(_collisions[j], dt);
			    	}
			    }
			    else
			    {
			    	for (j = origNumCollisions; j < _collisions.length; j++)
			    	{
			    		PreProcessCollisionFn(_collisions[j],dt);
			    	}
			    }
			    origNumCollisions = _collisions.length;
				if (!gotOne)
				{
					break;
				}
			}
		}
		 
		public function ActivateObject(body:RigidBody):void
		{
			if (!body.Getmovable() || body.IsActive())
			{
				return;
			}
			body.SetActive();
			_activeBodies.push(body);
			var orig_num:uint=_collisions.length;
			_collisionSystem.DetectCollisions(body, _collisions);
			var other_body:RigidBody;
			var thisBody_normal:JNumber3D;
			for (var i:uint = orig_num; i < _collisions.length; i++)
			{
				other_body=_collisions[i].ObjInfo.body0;
				thisBody_normal=_collisions[i].DirToBody;
				if(other_body==body)
				{
					other_body=_collisions[i].ObjInfo.body1;
					thisBody_normal=JNumber3D.multiply(_collisions[i].DirToBody,-1);
				}
				if (!other_body.IsActive() && JNumber3D.dot(other_body.Force, thisBody_normal) < -JNumber3D.NUM_TINY)
				{
					ActivateObject(other_body);
				}
			}
		}
		 
		private function DampAllActiveBodies():void
		{
			for (var i:String in _activeBodies)
			{
				_activeBodies[i].DampForDeactivation();
			}
		}
		 
		private function TryToActivateAllFrozenObjects():void
		{
			for (var i:String in _bodies)
			{
				if (!_bodies[i].IsActive())
				{
					if (_bodies[i].GetShouldBeActive())
                    {
						ActivateObject(_bodies[i]);
					}
					else
					{
						if (_bodies[i].GetVelChanged())
						{
							_bodies[i].SetVelocity(JNumber3D.ZERO);
							_bodies[i].SetAngVel(JNumber3D.ZERO);
							_bodies[i].ClearVelChanged();
						}
					}
				}
			}
		}
		
		private function ActivateAllFrozenObjectsLeftHanging():void
		{
			var other_body:RigidBody;
			for(var i:String in _bodies)
			{
				if(_bodies[i].IsActive())
				{
					_bodies[i].DoMovementActivations();
					if(_bodies[i].Collisions.length>0)
					{
						for(var j:String in _bodies[i].Collisions)
						{
							other_body=_bodies[i].Collisions[j].ObjInfo.body0;
							if(other_body==_bodies[i])
							{
								other_body=_bodies[i].Collisions[j].ObjInfo.body1;
							}
							
							if(!other_body.IsActive())
							{
								_bodies[i].AddMovementActivation(_bodies[i].CurrentState.Position,other_body);
							}
						}
					}
				}
			}
		}
		
		private function UpdateAllVelocities(dt:Number):void
		{
			for (var i:String in _activeBodies)
			{
				_activeBodies[i].UpdateVelocity(dt);
			}
		}
		private function UpdateAllPositions(dt:Number):void
		{
			for (var i:String in _activeBodies)
			{
				_activeBodies[i].UpdatePositionWithAux(dt);
			}
		}
		private function NotifyAllPostPhysics(dt:Number):void
		{
			for (var i:String in _bodies)
			{
				_bodies[i].PostPhysics(dt);
			}
		}
		private function UpdateAllObject3D():void
		{
			for (var i:String in _bodies)
			{
				_bodies[i].updateObject3D();
			}
		}
		
		private function LimitAllVelocities():void
		{
			for (var i:String in _activeBodies)
			{
				_activeBodies[i].LimitVel();
				_activeBodies[i].LimitAngVel();
			}
		}
		 
		private function TryToFreezeAllObjects(dt:Number):void
		{
			for (var i:String in _activeBodies)
			{
				_activeBodies[i].TryToFreeze(dt);
			}
		}
		
		private function DetectAllCollisionsStore(dt:Number):void
		{
			for(var i:String in _activeBodies)
			{
				_activeBodies[i].StoreState();
			}
			UpdateAllVelocities(dt);
			UpdateAllPositions(dt);
			
			for(i in _bodies)
			{
				_bodies[i].Collisions=new Array();
			}
			_collisions=new Array();
			_collisionSystem.DetectAllCollisions(_activeBodies, _collisions);
			
			for(i in _activeBodies)
			{
				_activeBodies[i].RestoreState();
			}
		}
		
		private function DetectAllCollisionsDirect(dt:Number):void
		{
			for(var i:String in _bodies)
			{
				_bodies[i].Collisions = new Array();
			}
			_collisions=new Array();
			_collisionSystem.DetectAllCollisions(_activeBodies, _collisions);
		}
		
		private function CopyAllCurrentStatesToOld():void
		{
			for (var i:String in _bodies)
			{
				if (_bodies[i].IsActive() || _bodies[i].GetVelChanged())
				{
					_bodies[i].CopyCurrentStateToOld();
				}
			}
		}
		 
		private function FindAllActiveBodies():void
		{
			_activeBodies = new Array();
			for (var i:String in _bodies)
			{
				if (_bodies[i].IsActive())
				{
					_activeBodies.push(_bodies[i]);
				}
			}
		}
		
		public function Integrate(dt:Number):void
		{
			_doingIntegration = true;
			
			FindAllActiveBodies();
			CopyAllCurrentStatesToOld();
			 
			GetAllExternalForces(dt);
			DetectAllCollisionsFn(dt);
			HandleAllConstraints(dt, JConfig.numCollisionIterations, false);
			UpdateAllVelocities(dt);
			HandleAllConstraints(dt, JConfig.numContactIterations, true);
			 
			DampAllActiveBodies();
			TryToFreezeAllObjects(dt);
			ActivateAllFrozenObjectsLeftHanging();
			 
			//LimitAllVelocities();
			UpdateAllPositions(dt);
			NotifyAllPostPhysics(dt);
			
			UpdateAllObject3D();
			if (JConfig.solverType == "ACCUMULATED")
			{
				UpdateContactCache();
			}
			for (var i:String in _bodies)
			{
				_bodies[i].ClearForces();
			}
			 
			_doingIntegration = false;
		}
	}
	
}

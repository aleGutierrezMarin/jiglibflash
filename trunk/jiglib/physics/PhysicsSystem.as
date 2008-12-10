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

	import flash.utils.getTimer;
	import jiglib.collision.*;
	import jiglib.math.*;
	import jiglib.cof.JConfig;
	
	public class PhysicsSystem {
		
		private static var _currentPhysicsSystem:PhysicsSystem;
		
		private const _maxVelMag:Number = 0.5;
        private const _minVelForProcessing:Number = 0.001;
		
		
		private var _bodies:Array;
		private var _activeBodies:Array;
		private var _collisions:Array;
		private var _constraints:Array;
		 
		 
		private var _gravity:JNumber3D;
		
		private var _solverType:String;
		private var _doingIntegration:Boolean;
		
		private var PreProcessCollisionFn:Function;
		private var PreProcessContactFn:Function;
		private var ProcessCollisionFn:Function;
		private var ProcessContactFn:Function;
		
		private var _collisionSystem:CollisionSystem;
		
		public static function getInstance():PhysicsSystem
	    {
	    	if (!_currentPhysicsSystem) {
			    _currentPhysicsSystem = new PhysicsSystem();
		    }
		    return _currentPhysicsSystem;
	    }
		
		public function PhysicsSystem() {
			
			SetSolverType(JConfig.solverType);
			_doingIntegration = false;
			_bodies = new Array();
			_collisions = new Array();
			_activeBodies = new Array();
			
			_collisionSystem = new CollisionSystem();
			
			SetCollisionFns();
			SetGravity(JNumber3D.multiply(JNumber3D.UP, -10));
		}
		 
		private function GetAllExternalForces():void
		{
			for (var i:String in _bodies)
			{
				_bodies[i].AddGravity();
			}
		}
		 
		public function SetGravity(gravity:JNumber3D):void
		{
			_gravity = gravity;
		}
		public function get Gravity():JNumber3D
		{
			return _gravity;
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
		
		public function SetSolverType(type:String):void
		{
			_solverType = type;
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
		
		private function PreProcessCollision(collision:CollisionInfo, dt:Number):void
		{
			var body0:RigidBody=collision.ObjInfo.body0;
			var body1:RigidBody=collision.ObjInfo.body1;
			
			var N:JNumber3D=collision.DirToBody;
			var timescale:Number = JConfig.numPenetrationRelaxationTimesteps * dt;
			var approachScale:Number;
			var ptInfo:CollPointInfo;
			var tempV:JNumber3D;
			for(var i:int=0; i<collision.PointInfo.length; i++)
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
		
		private function ProcessCollision(collision:CollisionInfo, dt:Number):void
		{
			var body0:RigidBody=collision.ObjInfo.body0;
			var body1:RigidBody=collision.ObjInfo.body1;
			 
			var N:JNumber3D=collision.DirToBody;
			 
			var deltaVel:Number;
			var normalVel:Number;
			var finalNormalVel:Number;
			var normalImpulse:Number;
			var impulse:JNumber3D;
			var Vr0:JNumber3D;
			var Vr1:JNumber3D;
			var ptInfo:CollPointInfo;
			
			for (var i:int = 0; i < collision.PointInfo.length; i++)
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
					if(denominator>JNumber3D.NUM_TINY)
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
		}
		
		private function SetCollisionFns():void
		{
			switch(_solverType)
			{
				case "FAST":
				    return;
				case "NORMAL":
				    PreProcessCollisionFn=PreProcessCollision;
					PreProcessContactFn=PreProcessCollision;
					ProcessCollisionFn=ProcessCollision;
					ProcessContactFn=ProcessCollision;
					return;
				case "ACCUMULATED":
				    return;
			}
		}
		
		private function HandleAllConstraints(dt:Number, iter:int, forceInelastic:Boolean):void
		{
			var origNumCollisions:int = _collisions.length;
			if(forceInelastic)
			{
				for(var i:String in _collisions)
				{
					PreProcessContactFn(_collisions[i], dt);
					_collisions[i].Mat.Restitution=0;
				}
			}
			else
			{
				for(i in _collisions)
				{
					PreProcessCollisionFn(_collisions[i],dt);
				}
			}
			for (var step:int = 0; step < iter; step++)
			{
				for(i in _collisions)
				{
					if(forceInelastic)
					{
						ProcessContactFn(_collisions[i], dt);
					}
					else
					{
						ProcessCollisionFn(_collisions[i],dt);
					}
				}
				TryToActivateAllFrozenObjects();
				
				if(forceInelastic)
			    {
			    	for(var j:int=origNumCollisions;j<_collisions.length;j++)
			    	{
			    		PreProcessContactFn(_collisions[j], dt);
						_collisions[j].Mat.Restitution=0;
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
			var orig_num:int=_collisions.length;
			_collisionSystem.DetectCollisions(body, _collisions);
			var other_body:RigidBody;
			var thisBody_normal:JNumber3D;
			for (var i:int = orig_num; i < _collisions.length; i++)
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
				_activeBodies[i].UpdatePosition(dt);
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
		
		private function DetectAllCollisions(dt:Number):void
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
			
			SetCollisionFns();
			FindAllActiveBodies();
			CopyAllCurrentStatesToOld();
			 
			GetAllExternalForces();
			DetectAllCollisions(dt);
			HandleAllConstraints(dt, JConfig.numCollisionIterations, false);
			UpdateAllVelocities(dt);
			HandleAllConstraints(dt, JConfig.numContactIterations, true);
			 
			DampAllActiveBodies();
			TryToFreezeAllObjects(dt);
			ActivateAllFrozenObjectsLeftHanging();
			 
			LimitAllVelocities();
			UpdateAllPositions(dt);
			 
			for (var i:String in _bodies)
			{
				_bodies[i].ClearForces();
			}
			 
			_doingIntegration = false;
		}
	}
	
}

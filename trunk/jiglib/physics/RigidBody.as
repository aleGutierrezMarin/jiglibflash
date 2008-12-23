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

package jiglib.physics
{
	import jiglib.geometry.JObject3D;
	import jiglib.math.*;
	import jiglib.cof.JConfig;
	
	public class RigidBody
	{
		private static var idCounter:int = 0;
		
		private var _id:int;
		private var _object3D:JObject3D;
		 
		private var _currPosition:JNumber3D;
		private var _currOrientation:JMatrix3D;
		private var _invOrientation:JMatrix3D;
		private var _currLinVelocity:JNumber3D;
	    private var _currRotVelocity:JNumber3D;
		private var _currLinVelocityAux:JNumber3D;
		private var _currRotVelocityAux:JNumber3D;
		 
		private var _oldPosition:JNumber3D;
		private var _oldOrientation:JMatrix3D;
		private var _oldLinVelocity:JNumber3D;
	    private var _oldRotVelocity:JNumber3D;
		 
		private var _storedPosition:JNumber3D;
		private var _storedOrientation:JMatrix3D;
		private var _storedLinVelocity:JNumber3D;
	    private var _storedRotVelocity:JNumber3D;
		 
		private var _mass:Number;
		private var _invMass:Number;
		private var _bodyInertia:JMatrix3D;
		private var _bodyInvInertia:JMatrix3D;
		private var _worldInertia:JMatrix3D;
		private var _worldInvInertia:JMatrix3D;
		 
		private var _force:JNumber3D;
		private var _torque:JNumber3D;
		 
		private var _velChanged:Boolean;
		private var _activity:Boolean;
		private var _movable:Boolean;
		private var _origMovable:Boolean;
		private var _inactiveTime:Number;
		 
		private var _bodiesToBeActivatedOnMovement:Array;
		 
		private var _storedPositionForActivation:JNumber3D;
		private var _lastPositionForDeactivation:JNumber3D;
		private var _lastOrientationForDeactivation:JMatrix3D;
		
		public var Collisions:Array;
	     
	    public function RigidBody(obj:JObject3D, mov:Boolean = true)
	    {
			_id = idCounter++;
			
	    	_object3D = obj;
			_object3D.Position = new JNumber3D();
			_object3D.Orientation = JMatrix3D.IDENTITY;
			
			 
	    	_bodyInertia = JMatrix3D.IDENTITY;
	    	_bodyInvInertia = JMatrix3D.inverse(_bodyInertia);
			 
	    	_currPosition = new JNumber3D();
			_currOrientation = JMatrix3D.IDENTITY;
			_invOrientation = JMatrix3D.inverse(_currOrientation);
			_currLinVelocity = new JNumber3D();
			_currRotVelocity = new JNumber3D();
			_currLinVelocityAux = new JNumber3D();
			_currRotVelocityAux = new JNumber3D();
			
			_oldPosition = new JNumber3D();
			_oldOrientation = JMatrix3D.IDENTITY;
			_oldLinVelocity = new JNumber3D();
			_oldRotVelocity = new JNumber3D();
			
			_storedPosition = new JNumber3D();
			_storedOrientation = JMatrix3D.IDENTITY;
			_storedLinVelocity = new JNumber3D();
			_storedRotVelocity = new JNumber3D();
			 
	    	_force = new JNumber3D();
	    	_torque = new JNumber3D();
	    	 
			_velChanged = false;
			_activity = mov;
			_movable = mov;
			_origMovable = mov;
			_inactiveTime = 0;
			
			setMass(1);
			
			Collisions=new Array();
			_storedPositionForActivation = new JNumber3D();
			_bodiesToBeActivatedOnMovement = new Array();
			_lastPositionForDeactivation = _currPosition.clone();
			_lastOrientationForDeactivation = JMatrix3D.clone(_currOrientation);
	    }
		
		public function SetOrientation(orient:JMatrix3D):void
		{
			_currOrientation.copy(orient);
			_invOrientation = JMatrix3D.Transpose(_currOrientation);
			_worldInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currOrientation, _bodyInertia), _invOrientation);
			_worldInvInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currOrientation, _bodyInvInertia), _invOrientation);
		}
		
		public function MoveTo(pos:JNumber3D, orientation:JMatrix3D):void
		{
			pos.copyTo(_currPosition);
			SetOrientation(orientation);
			_currLinVelocity = JNumber3D.ZERO;
			_currRotVelocity = JNumber3D.ZERO;
			CopyCurrentStateToOld();
			updateObject3D();
		}
		
		public function SetVelocity(vel:JNumber3D):void
		{
			vel.copyTo(_currLinVelocity);
		}
		public function SetAngVel(angVel:JNumber3D):void
		{
			angVel.copyTo(_currRotVelocity);
		}
		public function SetVelocityAux(vel:JNumber3D):void
		{
			vel.copyTo(_currLinVelocityAux);
		}
		public function SetAngVelAux(angVel:JNumber3D):void
		{
			angVel.copyTo(_currRotVelocityAux);
		}
		
		public function AddGravity():void
		{
			if(!Getmovable())
			{
				return;
			}
	    	_force = JNumber3D.add(_force, JNumber3D.multiply(PhysicsSystem.getInstance().Gravity,_mass));
			_velChanged = true;
		}
	     
	    public function AddWorldTorque(t:JNumber3D):void
	    {
			if(!Getmovable())
			{
				return;
			}
	    	_torque = JNumber3D.add(_torque, t);
			_velChanged = true;
			SetActive();
	    }
	     
	    public function AddWorldForce(f:JNumber3D, p:JNumber3D):void
	    {
			if(!Getmovable())
			{
				return;
			}
	    	_force = JNumber3D.add(_force, f);
	        AddWorldTorque(JNumber3D.cross(f, JNumber3D.sub(p, _currPosition)));
			_velChanged = true;
			SetActive();
	    }
		 
		public function AddBodyForce(f:JNumber3D, p:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			JMatrix3D.multiplyVector(_currOrientation, f);
			JMatrix3D.multiplyVector(_currOrientation, p);
			AddWorldForce(f, JNumber3D.add(_currPosition, p));
		}
		 
		public function AddBodyTorque(t:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			JMatrix3D.multiplyVector(_currOrientation, t);
			AddWorldTorque(t);
		}
		 
		public function ClearForces():void
	    {
	    	_force = JNumber3D.ZERO;
	        _torque = JNumber3D.ZERO;
	    }
		 
		public function ApplyWorldImpulse(impulse:JNumber3D, pos:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			_currLinVelocity = JNumber3D.add(_currLinVelocity, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, JNumber3D.sub(pos, _currPosition));
			JMatrix3D.multiplyVector(_worldInvInertia, rotImpulse);
			_currRotVelocity = JNumber3D.add(_currRotVelocity, rotImpulse);
			
			_velChanged = true;
		}
		public function ApplyWorldImpulseAux(impulse:JNumber3D, pos:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			_currLinVelocityAux = JNumber3D.add(_currLinVelocityAux, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, JNumber3D.sub(pos, _currPosition));
			JMatrix3D.multiplyVector(_worldInvInertia, rotImpulse);
			_currRotVelocityAux = JNumber3D.add(_currRotVelocityAux, rotImpulse);
			
			_velChanged = true;
		}
		
		public function ApplyBodyWorldImpulse(impulse:JNumber3D, delta:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			_currLinVelocity = JNumber3D.add(_currLinVelocity, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, delta);
			JMatrix3D.multiplyVector(_worldInvInertia, rotImpulse);
			_currRotVelocity = JNumber3D.add(_currRotVelocity, rotImpulse);
			
			_velChanged = true;
		}
		public function ApplyBodyWorldImpulseAux(impulse:JNumber3D, delta:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			_currLinVelocityAux = JNumber3D.add(_currLinVelocityAux, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, delta);
			JMatrix3D.multiplyVector(_worldInvInertia, rotImpulse);
			_currRotVelocityAux = JNumber3D.add(_currRotVelocityAux, rotImpulse);
			
			_velChanged = true;
		}
		
		public function UpdateVelocity(dt:Number):void
		{
			if (!Getmovable() || !IsActive())
			{
				return;
			}
			_currLinVelocity = JNumber3D.add(_currLinVelocity, JNumber3D.multiply(_force, _invMass * dt));
			
			var rac:JNumber3D = JNumber3D.multiply(_torque, dt);
			JMatrix3D.multiplyVector(_worldInvInertia, rac);
			_currRotVelocity = JNumber3D.add(_currRotVelocity, rac);
			
			_currLinVelocity = JNumber3D.multiply(_currLinVelocity, 0.995);
	    	_currRotVelocity = JNumber3D.multiply(_currRotVelocity, 0.995);
		}
		 
		public function UpdatePosition(dt:Number):void
		{
			if (!Getmovable() || !IsActive())
			{
				return;
			}
			 
			_currPosition = JNumber3D.add(_currPosition, JNumber3D.multiply(_currLinVelocity, dt));
			
			var dir:JNumber3D = _currRotVelocity.clone();
			var ang:Number = dir.modulo;
			if (ang > 0)
			{
				dir.normalize();
				ang *= dt;
				var rot:JMatrix3D = JMatrix3D.rotationMatrix(dir.x, dir.y, dir.z, ang);
				_currOrientation = JMatrix3D.multiply(rot, _currOrientation);
			}
			SetOrientation(_currOrientation);
			
			updateObject3D();
		}
		public function UpdatePositionWithAux(dt:Number):void
		{
			if (!Getmovable() || !IsActive())
			{
				_currLinVelocityAux = JNumber3D.ZERO;
				_currRotVelocityAux = JNumber3D.ZERO;
				return;
			}
			var ga:int = PhysicsSystem.getInstance().GravityAxis;
			if (ga != -1)
			{
				_currLinVelocityAux.toArray()[(ga + 1) % 3] *= 0;
				_currLinVelocityAux.toArray()[(ga + 2) % 3] *= 0;
			}
			
			_currPosition = JNumber3D.add(_currPosition, JNumber3D.multiply(JNumber3D.add(_currLinVelocity, _currLinVelocityAux), dt));
			
			var dir:JNumber3D = JNumber3D.add(_currRotVelocity, _currRotVelocityAux);
			var ang:Number = dir.modulo;
			if (ang > 0)
			{
				dir.normalize();
				ang *= dt;
				var rot:JMatrix3D = JMatrix3D.rotationMatrix(dir.x, dir.y, dir.z, ang);
				_currOrientation = JMatrix3D.multiply(rot, _currOrientation);
			}
			_currLinVelocityAux = JNumber3D.ZERO;
			_currRotVelocityAux = JNumber3D.ZERO;
			SetOrientation(_currOrientation);
			
			updateObject3D();
		}
		 
		public function TryToFreeze(dt:Number):void
		{
			if (!Getmovable() || !IsActive())
			{
				return;
			}
			if (JNumber3D.sub(_currPosition, _lastPositionForDeactivation).modulo > JConfig.posThreshold)
			{
				_currPosition.copyTo(_lastPositionForDeactivation);
				_inactiveTime = 0;
				return;
			}
			
			var deltaMat:JMatrix3D = JMatrix3D.sub(_currOrientation, _lastOrientationForDeactivation);
			if (deltaMat.getCols()[0].modulo > JConfig.orientThreshold || 
			    deltaMat.getCols()[1].modulo > JConfig.orientThreshold || 
				deltaMat.getCols()[2].modulo > JConfig.orientThreshold)
			{
				_lastOrientationForDeactivation.copy(_currOrientation);
				_inactiveTime = 0;
				return;
			}
			if (GetShouldBeActive())
			{
				return;
			}
			_inactiveTime += dt;
			if (_inactiveTime > JConfig.deactivationTime)
			{
				_currPosition.copyTo(_lastPositionForDeactivation);
				_lastOrientationForDeactivation.copy(_currOrientation);
				SetInactive();
			}
		}
		
		public function setMass(m:Number):void
		{
			_mass=m;
			_invMass = 1 / m;
			
			setInertia(_object3D.GetInertiaProperties(m));
		}
		public function setInertia(i:JMatrix3D):void
		{
			_bodyInertia = JMatrix3D.clone(i);
	    	_bodyInvInertia = JMatrix3D.inverse(i);
			
			_worldInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currOrientation, _bodyInertia), _invOrientation);
			_worldInvInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currOrientation, _bodyInvInertia), _invOrientation);
		}
		
		public function IsActive():Boolean
		{
			return _activity;
		}
		
		public function Getmovable():Boolean
		{
			return _movable;
		}
		public function SetMovable(mov:Boolean):void
		{
			_movable=mov;
		}
		
		public function InternalSetImmovable():void
		{
			_origMovable = _movable;
			_movable = false;
		}
		public function InternalRestoreImmovable():void
		{
			_movable = _origMovable;
		}
		
		public function GetVelChanged():Boolean
		{
			return _velChanged;
		}
		public function ClearVelChanged():void
		{
			_velChanged = false;
		}
		 
		public function SetActive(activityFactor:Number = 1):void
		{
			_activity = true;
			_inactiveTime = (1 - activityFactor) * JConfig.deactivationTime;
		}
		public function SetInactive():void
		{
			_activity = false;
		}
		public function GetVelocity(relPos:JNumber3D):JNumber3D
		{
			return JNumber3D.add(_currLinVelocity,JNumber3D.cross(relPos,_currRotVelocity));
		}
		public function GetVelocityAux(relPos:JNumber3D):JNumber3D
		{
			return JNumber3D.add(_currLinVelocityAux,JNumber3D.cross(relPos,_currRotVelocityAux));
		}
		
		public function GetShouldBeActive():Boolean
		{
			return ((_currLinVelocity.modulo > JConfig.velThreshold) || 
                    (_currRotVelocity.modulo > JConfig.angVelThreshold));
		}
		public function GetShouldBeActiveAux():Boolean
		{
			return ((_currLinVelocityAux.modulo > JConfig.velThreshold) || 
                    (_currRotVelocityAux.modulo > JConfig.angVelThreshold));
		}
		
		public function DampForDeactivation():void
		{
			var r:Number = 0.5;
			var frac:Number = _inactiveTime / JConfig.deactivationTime;
			if (frac < r)
			{
				return;
			}
			
			var scale:Number = 1 - ((frac - r) / (1 - r));
			if (scale < 0)
			{
				scale = 0;
			}
			else if (scale > 1)
			{
				scale = 1;
			}
			_currLinVelocity = JNumber3D.multiply(_currLinVelocity, scale);
	    	_currRotVelocity = JNumber3D.multiply(_currRotVelocity, scale);
		}
		 
		public function DoMovementActivations():void
		{
			if (_bodiesToBeActivatedOnMovement.length == 0 || 
			    JNumber3D.sub(_currPosition, _storedPositionForActivation).modulo < JConfig.posThreshold)
			{
				return;
			}
			for (var i:int = 0; i < _bodiesToBeActivatedOnMovement.length; i++ )
			{
				PhysicsSystem.getInstance().ActivateObject(_bodiesToBeActivatedOnMovement[i]);
			}
			_bodiesToBeActivatedOnMovement = new Array();
		}
		
		public function AddMovementActivation(pos:JNumber3D, otherBody:RigidBody):void
		{
			for (var i:int = 0; i < _bodiesToBeActivatedOnMovement.length; i++ )
			{
				if (_bodiesToBeActivatedOnMovement[i] == otherBody)
				{
					return;
				}
			}
			if (_bodiesToBeActivatedOnMovement.length == 0)
			{
				_storedPositionForActivation = pos;
			}
			_bodiesToBeActivatedOnMovement.push(otherBody);
		}
		
		public function SetConstraintsAndCollisionsUnsatisfied():void
		{
			for (var i:String in Collisions)
			{
				Collisions[i].Satisfied = false;
			}
		}
		
		public function CopyCurrentStateToOld():void
		{
			_currPosition.copyTo(_oldPosition);
			_oldOrientation.copy(_currOrientation);
			_currLinVelocity.copyTo(_oldLinVelocity);
			_currRotVelocity.copyTo(_oldRotVelocity);
		}
		
		public function StoreState():void
		{
			_currPosition.copyTo(_storedPosition);
			_storedOrientation.copy(_currOrientation);
			_currLinVelocity.copyTo(_storedLinVelocity);
			_currRotVelocity.copyTo(_storedRotVelocity);
		}
		 
		public function RestoreState():void
		{
			_storedPosition.copyTo(_currPosition);
			_currOrientation.copy(_storedOrientation);
			_storedLinVelocity.copyTo(_currLinVelocity);
			_storedRotVelocity.copyTo(_currRotVelocity);
			
			SetOrientation(_currOrientation);
		}
		 
		public function get CurrentState():Object
		{
			var obj:Object = new Object();
			obj.Position = _currPosition;
			obj.Orientation = _currOrientation;
			obj.LinVelocity = _currLinVelocity;
			obj.RotVelocity = _currRotVelocity;
			 
			return obj;
		}
		 
		public function get OldState():Object
		{
			var obj:Object = new Object();
			obj.Position = _oldPosition;
			obj.Orientation = _oldOrientation;
			obj.LinVelocity = _oldLinVelocity;
			obj.RotVelocity = _oldRotVelocity;
			 
			return obj;
		}
		
		public function get ID():int
		{
			return _id;
		}
		 
		public function get BodySkin():JObject3D
		{
			return _object3D;
		}
		
		public function get Force():JNumber3D
		{
			return _force;
		}
		 
		public function get Mass():Number
		{
			return _mass;
		}
		public function get InvMass():Number
		{
			return _invMass;
		}
		
		public function get WorldInertia():JMatrix3D
		{
			return _worldInertia;
		}
		public function get WorldInvInertia():JMatrix3D
		{
			return _worldInvInertia;
		}
		
		public function LimitVel():void
		{
			if(_currLinVelocity.x<-100)
			{
				_currLinVelocity.x=-100;
			}
			else if(_currLinVelocity.x>100)
			{
				_currLinVelocity.x=100;
			}
			if(_currLinVelocity.y<-100)
			{
				_currLinVelocity.y=-100;
			}
			else if(_currLinVelocity.y>100)
			{
				_currLinVelocity.y=100;
			}
			if(_currLinVelocity.z<-100)
			{
				_currLinVelocity.z=-100;
			}
			else if(_currLinVelocity.z>100)
			{
				_currLinVelocity.z=100;
			}
		}
		public function LimitAngVel():void
		{
			if(_currRotVelocity.x<-50)
			{
				_currRotVelocity.x=-50;
			}
			else if(_currRotVelocity.x>50)
			{
				_currRotVelocity.x=50;
			}
			if(_currRotVelocity.y<-50)
			{
				_currRotVelocity.y=-50;
			}
			else if(_currRotVelocity.y>50)
			{
				_currRotVelocity.y=50;
			}
			if(_currRotVelocity.z<-50)
			{
				_currRotVelocity.z=-50;
			}
			else if(_currRotVelocity.z>50)
			{
				_currRotVelocity.z=50;
			}
		}
		 
		public function updateObject3D():void
	    {
			_object3D.setTransform(_currPosition, _currOrientation);
	    }
	}
}
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
	import org.papervision3d.core.math.*;
	import org.papervision3d.objects.DisplayObject3D;
	
	import jiglib.math.*;
	import jiglib.cof.JConfig;
	import jiglib.geometry.JSegment;
	import jiglib.physics.constraint.JConstraint;
	
	public class RigidBody
	{
		private static var idCounter:int = 0;
		
		private var _id:int;
		private var _skin:DisplayObject3D;
		 
		private var _currState:PhysicsState;
		private var _oldState:PhysicsState;
		private var _storeState:PhysicsState;
		private var _invOrientation:JMatrix3D;
		private var _currLinVelocityAux:JNumber3D;
		private var _currRotVelocityAux:JNumber3D;
		 
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
		public var Material:MaterialProperties;
		
		
		protected var _type:String;
		protected var _boundingSphere:Number;
	     
	    public function RigidBody(skin:DisplayObject3D, mov:Boolean = true)
	    {
			_id = idCounter++;
			 
			_skin = skin;
			Material = new MaterialProperties();
			 
	    	_bodyInertia = JMatrix3D.IDENTITY;
	    	_bodyInvInertia = JMatrix3D.inverse(_bodyInertia);
			 
			_currState = new PhysicsState();
			_oldState = new PhysicsState();
			_storeState = new PhysicsState();
			_invOrientation = JMatrix3D.inverse(_currState.Orientation);
			_currLinVelocityAux = new JNumber3D();
			_currRotVelocityAux = new JNumber3D();
			 
	    	_force = new JNumber3D();
	    	_torque = new JNumber3D();
	    	 
			_origMovable = mov;
			_velChanged = false;
			_inactiveTime = 0;
			 
			_activity = mov;
			_movable = mov;
			 
			Collisions=new Array();
			_storedPositionForActivation = new JNumber3D();
			_bodiesToBeActivatedOnMovement = new Array();
			_lastPositionForDeactivation = _currState.Position.clone();
			_lastOrientationForDeactivation = JMatrix3D.clone(_currState.Orientation);
			
			_type = "Object3D";
			_boundingSphere = 0;
	    }
		 
		public function SetOrientation(orient:JMatrix3D):void
		{
			_currState.Orientation.copy(orient);
			_invOrientation = JMatrix3D.Transpose(_currState.Orientation);
			_worldInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currState.Orientation, _bodyInertia), _invOrientation);
			_worldInvInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currState.Orientation, _bodyInvInertia), _invOrientation);
		}
		 
		public function MoveTo(pos:JNumber3D, orientation:JMatrix3D):void
		{
			pos.copyTo(_currState.Position);
			SetOrientation(orientation);
			_currState.LinVelocity = JNumber3D.ZERO;
			_currState.RotVelocity = JNumber3D.ZERO;
			CopyCurrentStateToOld();
		}
		 
		public function SetVelocity(vel:JNumber3D):void
		{
			vel.copyTo(_currState.LinVelocity);
		}
		public function SetAngVel(angVel:JNumber3D):void
		{
			angVel.copyTo(_currState.RotVelocity);
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
		
		public function AddExternalForces(dt:Number):void
		{
			AddGravity();
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
	        AddWorldTorque(JNumber3D.cross(f, JNumber3D.sub(p, _currState.Position)));
			_velChanged = true;
			SetActive();
	    }
		 
		public function AddBodyForce(f:JNumber3D, p:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			JMatrix3D.multiplyVector(_currState.Orientation, f);
			JMatrix3D.multiplyVector(_currState.Orientation, p);
			AddWorldForce(f, JNumber3D.add(_currState.Position, p));
		}
		 
		public function AddBodyTorque(t:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			JMatrix3D.multiplyVector(_currState.Orientation, t);
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
			_currState.LinVelocity = JNumber3D.add(_currState.LinVelocity, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, JNumber3D.sub(pos, _currState.Position));
			JMatrix3D.multiplyVector(_worldInvInertia, rotImpulse);
			_currState.RotVelocity = JNumber3D.add(_currState.RotVelocity, rotImpulse);
			
			_velChanged = true;
		}
		public function ApplyWorldImpulseAux(impulse:JNumber3D, pos:JNumber3D):void
		{
			if(!Getmovable())
			{
				return;
			}
			_currLinVelocityAux = JNumber3D.add(_currLinVelocityAux, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, JNumber3D.sub(pos, _currState.Position));
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
			_currState.LinVelocity = JNumber3D.add(_currState.LinVelocity, JNumber3D.multiply(impulse, _invMass));
			
			var rotImpulse:JNumber3D = JNumber3D.cross(impulse, delta);
			JMatrix3D.multiplyVector(_worldInvInertia, rotImpulse);
			_currState.RotVelocity = JNumber3D.add(_currState.RotVelocity, rotImpulse);
			
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
			_currState.LinVelocity = JNumber3D.add(_currState.LinVelocity, JNumber3D.multiply(_force, _invMass * dt));
			
			var rac:JNumber3D = JNumber3D.multiply(_torque, dt);
			JMatrix3D.multiplyVector(_worldInvInertia, rac);
			_currState.RotVelocity = JNumber3D.add(_currState.RotVelocity, rac);
			
			_currState.LinVelocity = JNumber3D.multiply(_currState.LinVelocity, 0.995);
	    	_currState.RotVelocity = JNumber3D.multiply(_currState.RotVelocity, 0.995);
		}
		 
		public function UpdatePosition(dt:Number):void
		{
			if (!Getmovable() || !IsActive())
			{
				return;
			}
			 
			_currState.Position = JNumber3D.add(_currState.Position, JNumber3D.multiply(_currState.LinVelocity, dt));
			
			var dir:JNumber3D = _currState.RotVelocity.clone();
			var ang:Number = dir.modulo;
			if (ang > 0)
			{
				dir.normalize();
				ang *= dt;
				var rot:JMatrix3D = JMatrix3D.rotationMatrix(dir.x, dir.y, dir.z, ang);
				_currState.Orientation = JMatrix3D.multiply(rot, _currState.Orientation);
			}
			SetOrientation(_currState.Orientation);
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
			
			_currState.Position = JNumber3D.add(_currState.Position, JNumber3D.multiply(JNumber3D.add(_currState.LinVelocity, _currLinVelocityAux), dt));
			
			var dir:JNumber3D = JNumber3D.add(_currState.RotVelocity, _currRotVelocityAux);
			var ang:Number = dir.modulo;
			if (ang > 0)
			{
				dir.normalize();
				ang *= dt;
				var rot:JMatrix3D = JMatrix3D.rotationMatrix(dir.x, dir.y, dir.z, ang);
				_currState.Orientation = JMatrix3D.multiply(rot, _currState.Orientation);
			}
			_currLinVelocityAux = JNumber3D.ZERO;
			_currRotVelocityAux = JNumber3D.ZERO;
			SetOrientation(_currState.Orientation);
		}
		
		public function PostPhysics(dt:Number):void
		{
		}
		 
		public function TryToFreeze(dt:Number):void
		{
			if (!Getmovable() || !IsActive())
			{
				return;
			}
			if (JNumber3D.sub(_currState.Position, _lastPositionForDeactivation).modulo > JConfig.posThreshold)
			{
				_currState.Position.copyTo(_lastPositionForDeactivation);
				_inactiveTime = 0;
				return;
			}
			
			var deltaMat:JMatrix3D = JMatrix3D.sub(_currState.Orientation, _lastOrientationForDeactivation);
			if (deltaMat.getCols()[0].modulo > JConfig.orientThreshold || 
			    deltaMat.getCols()[1].modulo > JConfig.orientThreshold || 
				deltaMat.getCols()[2].modulo > JConfig.orientThreshold)
			{
				_lastOrientationForDeactivation.copy(_currState.Orientation);
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
				_currState.Position.copyTo(_lastPositionForDeactivation);
				_lastOrientationForDeactivation.copy(_currState.Orientation);
				SetInactive();
			}
		}
		
		public function setMass(m:Number):void
		{
			_mass=m;
			_invMass = 1 / m;
			
			setInertia(GetInertiaProperties(m));
		}
		public function setInertia(i:JMatrix3D):void
		{
			_bodyInertia = JMatrix3D.clone(i);
	    	_bodyInvInertia = JMatrix3D.inverse(i);
			
			_worldInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currState.Orientation, _bodyInertia), _invOrientation);
			_worldInvInertia = JMatrix3D.multiply(JMatrix3D.multiply(_currState.Orientation, _bodyInvInertia), _invOrientation);
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
			if (_movable)
			{
				_activity = true;
				_inactiveTime = (1 - activityFactor) * JConfig.deactivationTime;
			}
		}
		public function SetInactive():void
		{
			if (_movable)
			{
				_activity = false;
			}
		}
		public function GetVelocity(relPos:JNumber3D):JNumber3D
		{
			return JNumber3D.add(_currState.LinVelocity,JNumber3D.cross(relPos,_currState.RotVelocity));
		}
		public function GetVelocityAux(relPos:JNumber3D):JNumber3D
		{
			return JNumber3D.add(_currLinVelocityAux,JNumber3D.cross(relPos,_currRotVelocityAux));
		}
		
		public function GetShouldBeActive():Boolean
		{
			return ((_currState.LinVelocity.modulo > JConfig.velThreshold) || 
                    (_currState.RotVelocity.modulo > JConfig.angVelThreshold));
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
			_currState.LinVelocity = JNumber3D.multiply(_currState.LinVelocity, scale);
	    	_currState.RotVelocity = JNumber3D.multiply(_currState.RotVelocity, scale);
		}
		 
		public function DoMovementActivations():void
		{
			if (_bodiesToBeActivatedOnMovement.length == 0 || 
			    JNumber3D.sub(_currState.Position, _storedPositionForActivation).modulo < JConfig.posThreshold)
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
		
		public function SegmentIntersect(out:Object, seg:JSegment):Boolean
		{
			return false;
		}
		public function GetInertiaProperties(mass:Number):JMatrix3D
		{
			return new JMatrix3D();
		}
		
		public function hitTestObject3D(obj3D:RigidBody):Boolean
		{
			var num1:Number = JNumber3D.sub(_currState.Position, obj3D.CurrentState.Position).modulo;
			var num2:Number = _boundingSphere + obj3D.BoundingSphere;
			
			if (num1 <= num2)
			{
				return true;
			}
			
			return false;
		}
		
		public function CopyCurrentStateToOld():void
		{
			_currState.Position.copyTo(_oldState.Position);
			_oldState.Orientation.copy(_currState.Orientation);
			_currState.LinVelocity.copyTo(_oldState.LinVelocity);
			_currState.RotVelocity.copyTo(_oldState.RotVelocity);
		}
		
		public function StoreState():void
		{
			_currState.Position.copyTo(_storeState.Position);
			_storeState.Orientation.copy(_currState.Orientation);
			_currState.LinVelocity.copyTo(_storeState.LinVelocity);
			_currState.RotVelocity.copyTo(_storeState.RotVelocity);
		}
		 
		public function RestoreState():void
		{
			_storeState.Position.copyTo(_currState.Position);
			_currState.Orientation.copy(_storeState.Orientation);
			_storeState.LinVelocity.copyTo(_currState.LinVelocity);
			_storeState.RotVelocity.copyTo(_currState.RotVelocity);
			
			SetOrientation(_currState.Orientation);
		}
		 
		public function get CurrentState():PhysicsState
		{
			return _currState;
		}
		 
		public function get OldState():PhysicsState
		{
			return _oldState;
		}
		
		public function get ID():int
		{
			return _id;
		}
		
		public function get Type():String
		{
			return _type;
		}
		 
		public function get BodySkin():DisplayObject3D
		{
			return _skin;
		}
		
		public function get BoundingSphere():Number
		{
			return _boundingSphere;
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
			if(_currState.LinVelocity.x<-100)
			{
				_currState.LinVelocity.x=-100;
			}
			else if(_currState.LinVelocity.x>100)
			{
				_currState.LinVelocity.x=100;
			}
			if(_currState.LinVelocity.y<-100)
			{
				_currState.LinVelocity.y=-100;
			}
			else if(_currState.LinVelocity.y>100)
			{
				_currState.LinVelocity.y=100;
			}
			if(_currState.LinVelocity.z<-100)
			{
				_currState.LinVelocity.z=-100;
			}
			else if(_currState.LinVelocity.z>100)
			{
				_currState.LinVelocity.z=100;
			}
		}
		public function LimitAngVel():void
		{
			if(_currState.RotVelocity.x<-50)
			{
				_currState.RotVelocity.x=-50;
			}
			else if(_currState.RotVelocity.x>50)
			{
				_currState.RotVelocity.x=50;
			}
			if(_currState.RotVelocity.y<-50)
			{
				_currState.RotVelocity.y=-50;
			}
			else if(_currState.RotVelocity.y>50)
			{
				_currState.RotVelocity.y=50;
			}
			if(_currState.RotVelocity.z<-50)
			{
				_currState.RotVelocity.z=-50;
			}
			else if(_currState.RotVelocity.z>50)
			{
				_currState.RotVelocity.z=50;
			}
		}
		 
		public function getTransform():JMatrix3D
		{
			var tr:JMatrix3D=new JMatrix3D();
			tr.n11=_skin.transform.n11; tr.n12=_skin.transform.n12; tr.n13=_skin.transform.n13; tr.n14=_skin.transform.n14;
			tr.n21=_skin.transform.n21; tr.n22=_skin.transform.n22; tr.n23=_skin.transform.n23; tr.n24=_skin.transform.n24;
			tr.n31=_skin.transform.n31; tr.n32=_skin.transform.n32; tr.n33=_skin.transform.n33; tr.n34=_skin.transform.n34;
			tr.n41=_skin.transform.n41; tr.n42=_skin.transform.n42; tr.n43=_skin.transform.n43; tr.n44=_skin.transform.n44;
			 
			return tr;
		}
		
		public function updateObject3D():void
	    {
			var p:Number3D=new Number3D(_currState.Position.x,_currState.Position.y,_currState.Position.z);
			var o:Matrix3D=new Matrix3D();
			o.n11=_currState.Orientation.n11; o.n12=_currState.Orientation.n12; o.n13=_currState.Orientation.n13; o.n14=_currState.Orientation.n14;
			o.n21=_currState.Orientation.n21; o.n22=_currState.Orientation.n22; o.n23=_currState.Orientation.n23; o.n24=_currState.Orientation.n24;
			o.n31=_currState.Orientation.n31; o.n32=_currState.Orientation.n32; o.n33=_currState.Orientation.n33; o.n34=_currState.Orientation.n34;
			o.n41=_currState.Orientation.n41; o.n42=_currState.Orientation.n42; o.n43=_currState.Orientation.n43; o.n44=_currState.Orientation.n44;
			
			_skin.transform=Matrix3D.multiply(Matrix3D.translationMatrix(p.x, p.y, p.z), o);
	    }
	}
}
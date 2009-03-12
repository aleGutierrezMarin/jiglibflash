package jiglib.plugin {
	import jiglib.geometry.JSegment;
	import jiglib.math.JMatrix3D;
	import jiglib.math.JNumber3D;
	import jiglib.physics.MaterialProperties;
	import jiglib.physics.PhysicsState;
	import jiglib.physics.RigidBody;	

	/**
	 * PhysicsBody is the interface through which the users can access properties and methods
	 * of a body inside the JigLib physics system. 
	 * 
	 * @author bartekd
	 */
	public interface PhysicsBody {

		function get x():Number;
		function get y():Number;
		function get z():Number;

		function set x(px:Number):void;

		function set y(py:Number):void;

		function set z(pz:Number):void;
		
		
		function get rotationX():Number;

		function get rotationY():Number;

		function get rotationZ():Number;

		function set rotationX(px:Number):void;

		function set rotationY(py:Number):void;

		function set rotationZ(pz:Number):void;
	

		function get movable():Boolean;
		function set movable(mov:Boolean):void;
		
		function get skin():ISkin3D;
		
		function get material():MaterialProperties;
		
		// Review all the methods below in order to check if they are internal to the engine
		// or should be available as part of the API
		function setVelocity(vel:JNumber3D):void;
		function setAngVel(angVel:JNumber3D):void;
		function setVelocityAux(vel:JNumber3D):void;
		function setAngVelAux(angVel:JNumber3D):void;
		function addGravity():void;
		function addExternalForces(dt:Number):void;
		function addWorldTorque(t:JNumber3D):void;
		function addWorldForce(f:JNumber3D, p:JNumber3D):void;
		function addBodyForce(f:JNumber3D, p:JNumber3D):void;
		function addBodyTorque(t:JNumber3D):void;
		function clearForces():void;
		function applyWorldImpulse(impulse:JNumber3D, pos:JNumber3D):void;
		function applyWorldImpulseAux(impulse:JNumber3D, pos:JNumber3D):void;
		function applyBodyWorldImpulse(impulse:JNumber3D, delta:JNumber3D):void;
		function applyBodyWorldImpulseAux(impulse:JNumber3D, delta:JNumber3D):void;
		function updateVelocity(dt:Number):void;
		function updatePosition(dt:Number):void;
		function updatePositionWithAux(dt:Number):void;
		function postPhysics(dt:Number):void;
		function tryToFreeze(dt:Number):void;
		function setMass(m:Number):void;
		function setInertia(i:JMatrix3D):void;
		function isActive():Boolean;
		function getVelChanged():Boolean;
		function clearVelChanged():void;
		function setActive(activityFactor:Number = 1):void;
		function setInactive():void;
		function getVelocity(relPos:JNumber3D):JNumber3D;
		function getVelocityAux(relPos:JNumber3D):JNumber3D;
		function getShouldBeActive():Boolean;
		function getShouldBeActiveAux():Boolean;
		function dampForDeactivation():void;
		function doMovementActivations():void;
		function addMovementActivation(pos:JNumber3D, otherBody:RigidBody):void;
		function setConstraintsAndCollisionsUnsatisfied():void;
		function segmentIntersect(out:Object, seg:JSegment):Boolean;
		function getInertiaProperties(mass:Number):JMatrix3D;
		function hitTestObject3D(obj3D:RigidBody):Boolean;
		function copyCurrentStateToOld():void;
		function storeState():void;
		function restoreState():void;
		function get currentState():PhysicsState;
		function get oldState():PhysicsState;
		function get id():int;
		function get type():String;
		function get boundingSphere():Number;
		function get force():JNumber3D;
		function get mass():Number;
		function get invMass():Number;
		function get worldInertia():JMatrix3D;
		function get worldInvInertia():JMatrix3D;
		function limitVel():void;
		function limitAngVel():void;
		function getTransform():JMatrix3D;
		function updateObject3D():void;
	}
}

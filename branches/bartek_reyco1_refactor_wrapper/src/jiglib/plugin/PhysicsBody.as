package jiglib.plugin {
	import jiglib.physics.MaterialProperties;	
	
	/**
	 * Don't use I in the name of this one, 
	 * we do not want to remind people that 
	 * they are dealing with an interface.
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

		function get movable():Boolean;
		function set movable(mov:Boolean):void;
		
		function get skin():ISkin3D;
		
		function get material():MaterialProperties;
		
		// This is of course incomplete - a lot of RigidBody's methods will be added here
	}
}

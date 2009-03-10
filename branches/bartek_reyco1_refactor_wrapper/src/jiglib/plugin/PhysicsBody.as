package jiglib.plugin {
	import jiglib.physics.MaterialProperties;	
	
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

		function get movable():Boolean;
		function set movable(mov:Boolean):void;
		
		function get skin():ISkin3D;
		
		function get material():MaterialProperties;
		
		// This is of course incomplete - a lot of RigidBody's methods will be added here
	}
}

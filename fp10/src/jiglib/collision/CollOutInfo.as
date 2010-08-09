package jiglib.collision
{
	import flash.geom.Vector3D;
	
	import jiglib.physics.RigidBody;

	/**
	 * @author katopz
	 */
	public class CollOutInfo
	{
		public var fracOut:Number;
		public var posOut:Vector3D;
		public var normalOut:Vector3D;
		
		public var bodyOut:RigidBody;

		public function CollOutInfo(fracOut:Number = 0, posOut:Vector3D = null, normalOut:Vector3D = null, bodyOut:RigidBody = null)
		{
			this.fracOut = isNaN(fracOut)?0:fracOut;
			this.posOut = posOut?posOut:new Vector3D;
			this.normalOut = normalOut?normalOut:new Vector3D;
			
			this.bodyOut = bodyOut;
		}
	}
}
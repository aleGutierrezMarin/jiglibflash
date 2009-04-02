package jiglib.plugin {
	import jiglib.physics.PhysicsSystem;
	import jiglib.physics.RigidBody;
	
	import flash.utils.getTimer;	

	/**
	 * @author bartekd
	 */
	public class AbstractPhysics {
		
		private var initTime:int;
		private var stepTime:int;
		private var speed:Number;
		private var deltaTime:Number = 0;
		
		public function AbstractPhysics(speed:Number = 1) {
			this.speed = speed;
			initTime = getTimer();
		}
		
		public function addBody(body:RigidBody):void {
			PhysicsSystem.getInstance().addBody(body as RigidBody);
		}
		
		public function step():void {
			stepTime = getTimer();
	        deltaTime = ((stepTime - initTime) / 1000) * speed;
	        initTime = stepTime;
	        //PhysicsSystem.getInstance().integrate(deltaTime);
	        //trace(deltaTime);
	        // TODO: fix the timestep for now use a fixed timestep
	        PhysicsSystem.getInstance().integrate(1*speed);
		}
	}
}

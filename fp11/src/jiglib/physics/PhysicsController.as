package jiglib.physics
{

	public class PhysicsController
	{

		private var _controllerEnabled:Boolean;

		public function PhysicsController()
		{
			_controllerEnabled = false;
		}

		// implement this to apply whatever forces are needed to the objects this controls
		public function updateController(dt:Number):void
		{
		}

		// register with the physics system
		public function enableController():void
		{
			if (_controllerEnabled)
			{
				return;
			}
			_controllerEnabled = true;
			PhysicsSystem.getInstance().addController(this);
		}

		// deregister from the physics system
		public function disableController():void
		{
			if (!_controllerEnabled)
			{
				return;
			}
			_controllerEnabled = false;
			PhysicsSystem.getInstance().removeController(this);
		}

		// are we registered with the physics system?
		public function get controllerEnabled():Boolean
		{
			return _controllerEnabled;
		}
	}
}

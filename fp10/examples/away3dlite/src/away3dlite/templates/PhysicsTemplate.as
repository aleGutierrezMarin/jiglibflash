package away3dlite.templates
{
	import away3dlite.arcane;
	import away3dlite.core.render.*;
	import away3dlite.materials.ColorMaterial;
	import away3dlite.materials.WireframeMaterial;
	import away3dlite.primitives.Cube6;
	
	use namespace arcane;
	
	import jiglib.physics.RigidBody;
	import jiglib.plugin.away3dlite.Away3DLitePhysics;
	import away3dlite.core.clip.RectangleClipping;
	
	/**
	 * Physics Template
	 * 
 	 * @see http://away3d.googlecode.com/svn/trunk/fp10/Away3DLite/src
	 * @see http://jiglibflash.googlecode.com/svn/trunk/fp10/src
 	 * 
	 * @author katopz
	 */
	public class PhysicsTemplate extends Template
	{
		protected var physics:Away3DLitePhysics;
		protected var ground:RigidBody;
		
		/** @private */
		arcane override function init():void
		{
			super.init();
			
			view.renderer = renderer;
			view.clipping = clipping;
			
			build();
		}
		
		/**
		 * The renderer object used in the template.
		 */
		public var renderer:BasicRenderer = new BasicRenderer();
		
		/**
		 * The clipping object used in the template.
		 */
		public var clipping:RectangleClipping = new RectangleClipping();
		
		protected override function onInit():void
		{
			title += " | JigLibLite Physics";
			
			physics = new Away3DLitePhysics(scene, 10);
			ground = physics.createGround(new WireframeMaterial(), 1000, 0);
			ground.movable = false;
			ground.friction = 0.2;
			ground.restitution = 0.8;
		}
	
		protected function build():void
		{
			// override me
		}
	}
}
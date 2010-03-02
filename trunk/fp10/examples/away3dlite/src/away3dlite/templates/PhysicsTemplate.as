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
		private var cubes:Vector.<Cube6>;
		
		/** @private */
		arcane override function init():void
		{
			super.init();
			
			view.renderer = renderer || new BasicRenderer();
			view.clipping = clipping || new RectangleClipping();
			
			build();
		}
		
		/**
		 * The renderer object used in the template.
		 */
		public var renderer:BasicRenderer;
		
		/**
		 * The clipping object used in the template.
		 */
		public var clipping:RectangleClipping;
		
		protected override function onInit():void
		{
			title += " | JigLibLite Physics";
			
			physics = new Away3DLitePhysics(scene, 10);
			ground = physics.createGround(new WireframeMaterial(), 1000, 0);
			ground.movable = false;
			ground.friction = 0.2;
			ground.restitution = 0.8;
		}

		override public function set debug(val:Boolean):void
		{
			super.debug = val;
			
			if(val)
			{
				cubes = new Vector.<Cube6>(7);
				
				var length:int = 250;
				var oCube:Cube6 = new Cube6(new ColorMaterial(0xFFFFFF), 10, 10, 10);
				scene.addChild(oCube);
				cubes.push(oCube);
	
				var xCube:Cube6 = new Cube6(new ColorMaterial(0xFF0000), 10, 10, 10);
				xCube.x = length;
				scene.addChild(xCube);
				cubes.push(xCube);
	
				var yCube:Cube6 = new Cube6(new ColorMaterial(0x00FF00), 10, 10, 10);
				yCube.y = length;
				scene.addChild(yCube);
				cubes.push(yCube);
	
				var zCube:Cube6 = new Cube6(new ColorMaterial(0x0000FF), 10, 10, 10);
				zCube.z = length;
				scene.addChild(zCube);
				cubes.push(zCube);
				
				//
				var _xCube:Cube6 = new Cube6(new ColorMaterial(0x660000), 10, 10, 10);
				_xCube.x = -length;
				scene.addChild(_xCube);
				cubes.push(_xCube);
	
				var _yCube:Cube6 = new Cube6(new ColorMaterial(0x006600), 10, 10, 10);
				_yCube.y = -length;
				scene.addChild(_yCube);
				cubes.push(_yCube);
	
				var _zCube:Cube6 = new Cube6(new ColorMaterial(0x000066), 10, 10, 10);
				_zCube.z = -length;
				scene.addChild(_zCube);
				cubes.push(_zCube);
			}else{
				for each(var cube:Cube6 in cubes)
					scene.removeChild(cube);
					
				cubes = null;
			}
		}
		
		protected function build():void
		{
			// override me
		}
	}
}
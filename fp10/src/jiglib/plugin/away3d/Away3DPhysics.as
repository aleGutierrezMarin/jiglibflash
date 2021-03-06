package jiglib.plugin.away3d {
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import flash.display.BitmapData;
	
	import away3d.containers.View3D;
	import away3d.core.base.Mesh;
	import away3d.primitives.Cube;
	import away3d.primitives.Plane;
	import away3d.primitives.Sphere;
	
	import jiglib.geometry.JBox;
	import jiglib.geometry.JPlane;
	import jiglib.geometry.JSphere;
	import jiglib.geometry.JTerrain;
	import jiglib.geometry.JTriangleMesh;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.AbstractPhysics;
	import jiglib.plugin.away3d.Away3DTerrain;

	public class Away3DPhysics extends AbstractPhysics {
		
		private var view:View3D;

		public function Away3DPhysics(view:View3D, speed:Number = 1) {
			this.view = view;
			super(speed);
		}
		
		public function getMesh(body:RigidBody):Mesh {
			if(body.skin!=null){
				return Away3dMesh(body.skin).mesh;
			}else {
				return null;
			}
		}
		
		/**
		 *  InitObject - same as in the constructor of Sphere primitive.
		 *  Example of an initObject: {radius:100, segmentsW:8, segmentsH:6}
		 *  Refer to Away3D docs for more info.
		 */
		public function createSphere(initObject:Object):RigidBody {
			var r:Number = initObject["radius"];
			var sphere:Sphere = new Sphere(initObject);
			view.scene.addChild(sphere);
			var jsphere:JSphere = new JSphere(new Away3dMesh(sphere), r);
			addBody(jsphere);
			return jsphere;
		}
		
		/**
		 *  {width:100, height:100, depth:100}
		 */
		public function createCube(initObject:Object):RigidBody {
			var w:Number = initObject["width"];
			var d:Number = initObject["depth"];
			var h:Number = initObject["height"];
			var cube:Cube = new Cube(initObject);
			view.scene.addChild(cube);
			var jbox:JBox = new JBox(new Away3dMesh(cube), w, d, h);
			addBody(jbox);
			return jbox;
		}
		
		/**
		 * {width:100, height:100}
		 */
		public function createGround(initObject:Object, level:Number = 0):RigidBody {
			var ground:Plane = new Plane(initObject);
			view.scene.addChild(ground);
			
			var jGround:JPlane = new JPlane(new Away3dMesh(ground), new Vector3D(0, 1, 0));
			jGround.y = level;
			addBody(jGround);
			return jGround;
		}
		
		public function createTerrain(terrainHeightMap:BitmapData, initObject:Object):JTerrain {
			var terrainMap:Away3DTerrain = new Away3DTerrain(terrainHeightMap, initObject);
			view.scene.addChild(terrainMap);
			
			var terrain:JTerrain = new JTerrain(terrainMap);
			addBody(terrain);
			
			return terrain;
		}
		
		public function createMesh(skin:Mesh,initPosition:Vector3D,initOrientation:Matrix3D,maxTrianglesPerCell:int = 10, minCellSize:Number = 10):JTriangleMesh{
			var mesh:JTriangleMesh=new JTriangleMesh(new Away3dMesh(skin),initPosition,initOrientation,maxTrianglesPerCell,minCellSize);
			addBody(mesh);
			
			return mesh;
		}
	}
}

package 
{
	import away3d.cameras.Camera3D;
	import away3d.containers.View3D;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.methods.CelDiffuseMethod;
	import away3d.materials.methods.CelSpecularMethod;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.system.Capabilities;
	import flash.utils.getTimer;
	
	import jiglib.debug.Stats;
	import jiglib.math.JNumber3D;
	import jiglib.physics.PhysicsSystem;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.away3d4.Away3D4Mesh;
	import jiglib.plugin.away3d4.Away3D4Physics;

	/**
	 * Example	:	Grid system 
	 * Author	:	Ringo (www.ringo.nl)
	 */
	
	[SWF(width="970", height="560",backgroundColor="#000000", frameRate="60")]
	public class Away3DGridSystem extends Sprite 
	{
		// var settings
		private var numSpheres				: uint = 100; // how many sphere's to spawn at start, total objects max is 163 (164 total) due flash limits
		private var gridSystem				: Boolean = true; // use grid system for physics, otherwise bruteforce is used
		
		// 3d engine
		private var view 					: View3D;
		private var camera					: Camera3D;
		private var light 					: PointLight;
		
		// physics
		private var physics					: Away3D4Physics;
		private var ground					: RigidBody;
		private var rigidBodies				: Vector.<RigidBody>;
		
		// materials
		private var sleepMat				: ColorMaterial;
		private var awakeMat				: ColorMaterial;		

		// =================================================
		// Constructor
		// =================================================
		public function Away3DGridSystem():void {
			this.addEventListener(Event.ENTER_FRAME, tempLoop );
		}
		
		// Make sure the stage is ready
		private function tempLoop(event:Event):void {
			if ( stage.stageWidth > 0 && stage.stageHeight > 0 ) {
				this.removeEventListener( Event.ENTER_FRAME, tempLoop );
				init();
			}
		}

		private function init(event:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			setup();
		}
		
		private function setup():void {
			setupStage();
			setup3DEngine();
			setup3DPhysicEngine();
			setupMaterials();
			setup3DObjectsAndPhysics();
			
			this.addChild(new Stats(view,physics,gridSystem)); // new jiglib stats
			startEventListeners();
		}

		private function setup3DPhysicEngine():void {
			physics = new Away3D4Physics(view, 8);
			
			// setup grid system, only use it when having lots of objects otherwise it may slow down
			if (gridSystem) {
				physics.engine.setCollisionSystem(true,20,20,20,200,200,200); // 0,0,0 is start point of the grid to positive numbers, might change in future
			}
		}

		private function setupMaterials():void {
			sleepMat = new ColorMaterial(0xFF0000);
			sleepMat.lights = [light];
			sleepMat.ambientColor = 0xadadad;
			sleepMat.specular = .25;
		
			awakeMat = new ColorMaterial(0x3f2500);		
			awakeMat.lights = [light];
			awakeMat.ambientColor = 0xadadad;
			awakeMat.specular = .25;
		}

		private function setup3DObjectsAndPhysics():void
		{
			rigidBodies = new Vector.<RigidBody>;			

			// ground
			ground = physics.createGround(new ColorMaterial(0x00ce22), 10000, 10000, 4, 4,true,0);
			ground.rotationX = 90;
			ground.movable = false;
			ground.friction = 0.2;
			ground.restitution = 0.8;
			//var groundMesh:Mesh = Away3D4Mesh(ground.skin).mesh; // get ref. to mesh
			rigidBodies.push(ground);
			
			// spawn sphere's
			for (var i:int = 0;i<numSpheres;i++) {
				spawnNewSphere();
			}
		}
		
		private function spawnNewSphere(evt:Event=null):void
		{
			// material
			var color:uint = 0xFFFFFF * Math.random();
			var mat:ColorMaterial = new ColorMaterial(color);
			mat.lights = [light];
			mat.ambientColor = 0xadadad;
			mat.specular = .25;
			
			// physics and 3d object
			var radius:Number = 20;
			var nextSphere:RigidBody = physics.createSphere(mat,radius,24,16,true);
			nextSphere.friction = .1;
			nextSphere.restitution = .2;

			// position
			nextSphere.x = 500+2000*Math.random();
			nextSphere.y = 1000+1000*Math.random();
			nextSphere.z = 500+2000*Math.random();

			// enable mouseevents on mesh
			var meshSphere:Away3D4Mesh = nextSphere.skin as Away3D4Mesh;
			meshSphere.mesh.mouseEnabled = true;
			meshSphere.mesh.extra = { indexrigid: rigidBodies.length };
			meshSphere.mesh.addEventListener(MouseEvent3D.MOUSE_DOWN, onMouseClickSphere);
			
			rigidBodies.push(nextSphere);
		}
		
		private function onMouseClickSphere(mouseEvent:MouseEvent3D):void {
			trace("Click on Sphere with index: ", mouseEvent.target.extra.indexrigid);
			var rigidBodyClick:RigidBody = rigidBodies[mouseEvent.target.extra.indexrigid];
			trace("Is the 3D object active ?:", rigidBodyClick.isActive);
		}
		
		private function spawnNewCube(evt:Event=null):void
		{
			var width:Number = (Math.random() * 80) + 20;
			var depth:Number = (Math.random() * 50) + 20;
			var height:Number = (Math.random() * 80) + 20;
			var color:uint = 0xFFFFFF * Math.random();
			var mat:ColorMaterial = new ColorMaterial(color);
			var nextCube:RigidBody = physics.createCube(mat,width,height,depth);
			nextCube.x = 500+2000*Math.random();
			nextCube.y = 1000+1000*Math.random();
			nextCube.z = 500+2000*Math.random();
		}

		// loop
		private function handleEnterFrame(evt: Event) : void {
			physics.step();
			changeMatMeshActive(); // checks if object is active and chang
			view.render();
		}
		
		// Switch skins for active and not active state in the physic engine
		private function changeMatMeshActive():void {
			for each (var rigidBody:RigidBody in rigidBodies) {
				if (rigidBody.isActive) {
					var meshAwake:Away3D4Mesh = rigidBody.skin as Away3D4Mesh;
					meshAwake.mesh.material = awakeMat;
				}
				else {
					// exclude plane types
					if (rigidBody.type != "PLANE") { 
						var meshSleep:Away3D4Mesh = rigidBody.skin as Away3D4Mesh;
						meshSleep.mesh.material = sleepMat;
					}
				}
			} 
		}
		
		private function startEventListeners():void {
			this.addEventListener(Event.ENTER_FRAME, handleEnterFrame, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, setGravityUP, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, setGravityDown, false, 0, true);
		}			
		
		private function setGravityUP(mouseEvent:MouseEvent):void {
			trace("set gravity up");
			physics.engine.setGravity(JNumber3D.getScaleVector(Vector3D.Y_AXIS, 10));
		}
		
		private function setGravityDown(mouseEvent:MouseEvent):void {
			trace("set gravity down");
			physics.engine.setGravity(JNumber3D.getScaleVector(Vector3D.Y_AXIS, -10));
		}
		
		private function setup3DEngine():void {
			// camera
			camera = new Camera3D();
			camera.x = 1500;
			camera.y = 150;
			camera.z = 400;
			camera.rotationX = -5;
			
			view = new View3D(null,camera);
			view.backgroundColor = 0x0c00ff;
			
			if (Capabilities.os.toLowerCase().indexOf("windows") != -1)
				view.antiAlias = 4; // set aa

			// lights
			light = new PointLight(); 
			light.x = 0;
			light.y = 100;
			light.z = -2000;
			light.color = 0xfffdd2;
			light.specular = 1;
			view.scene.addChild(light);
			
			this.addChild(view);
		}
		
		
		private function setupStage():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.HIGH;
			stage.frameRate = 60;
		}
		
	}
} // eof
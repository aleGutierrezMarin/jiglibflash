package  
{
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jiglib.cof.JConfig;
	import jiglib.geometry.*;
	import jiglib.math.*;
	import jiglib.physics.*;
	import jiglib.physics.constraint.*;
	import jiglib.plugin.papervision3d.*;
	
	import org.papervision3d.cameras.CameraType;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.core.math.Plane3D;
	import org.papervision3d.core.utils.Mouse3D;
	import org.papervision3d.events.*;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.shadematerials.*;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.*;
	import org.papervision3d.view.BasicView;
	import org.papervision3d.view.layer.ViewportLayer;
	import org.papervision3d.view.layer.util.ViewportLayerSortMode;
	import org.papervision3d.view.stats.StatsView;
	
	[SWF(width="800", height="600", backgroundColor="#ffffff", frameRate="60")]
	public class StackingTest extends BasicView
	{
		private var mylight:PointLight3D;
		private var mouse3D:Mouse3D;
		private var shadeMateria:FlatShadeMaterial;
		private var vplObjects:ViewportLayer;
		
		private var ground:RigidBody;
		private var bodiesArr:Vector.<RigidBody>;
		
		private var onDraging:Boolean = false;
		
		private var currDragBody:RigidBody;
		private var dragConstraint:JConstraintWorldPoint;
		private var startMousePos:Vector3D;
		private var planeToDragOn:Plane3D;
		
		private var physics:Papervision3DPhysics;
		 
		public function StackingTest()
		{
			super(800, 600, true, true, CameraType.TARGET);
			
			stage.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseRelease);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			
			var text:TextField = new TextField();
			text.x = 600;
			text.y = 20;
			text.width = 200;
			text.text = "press num1: box stacking \n press num2: sphere stacking \n press num3: capsule stacking";
			addChild(text);
			
			init3D();
		}

		private function init3D():void
		{
			JConfig.doShockStep = true;
			
			physics = new Papervision3DPhysics(scene, 8);
			
			Mouse3D.enabled = true;
			mouse3D = viewport.interactiveSceneManager.mouse3D;
			viewport.containerSprite.sortMode = ViewportLayerSortMode.INDEX_SORT;
			
			mylight = new PointLight3D(true, true);
			mylight.y = 300;
			mylight.z = -400;
			
			camera.y = 300;
			camera.z = -650;
			var target:Sphere = new Sphere();
			target.y = 400;
			camera.target = target;
			 
			shadeMateria = new FlatShadeMaterial(mylight, 0x77ee77);
			
			ground = physics.createGround(shadeMateria, 1000, 10);
			ground.restitution = 0.9;
			viewport.getChildLayer(physics.getMesh(ground)).layerIndex = 1;

			vplObjects = new ViewportLayer(viewport,null);
			vplObjects.layerIndex = 2;
			vplObjects.sortMode = ViewportLayerSortMode.Z_SORT;
			viewport.containerSprite.addLayer(vplObjects);
			
			setupBoxStacking();
			
			var stats:StatsView = new StatsView(renderer);
			addChild(stats);
			 
			startRendering();
		}
		
		private function setupBoxStacking():void {
			shadeMateria = new FlatShadeMaterial(mylight,0xeeee00);
			shadeMateria.interactive = true;
			var materiaList :MaterialsList = new MaterialsList();
			materiaList.addMaterial(shadeMateria,"all");
			bodiesArr=new Vector.<RigidBody>();
			for (var i:int = 0; i < 25; i++)
			{
				bodiesArr[i] = physics.createCube(materiaList, 50, 50, 40);
				physics.getMesh(bodiesArr[i]).addEventListener(InteractiveScene3DEvent.OBJECT_PRESS, handleMousePress);
				bodiesArr[i].moveTo(new Vector3D(0, 0 + (40 * i + 40), 0));
				vplObjects.addDisplayObject3D(physics.getMesh(bodiesArr[i]));
			}
		}
		private function setupBallStacking():void {
			shadeMateria = new FlatShadeMaterial(mylight,0xeeee00);
			shadeMateria.interactive = true;
			bodiesArr = new Vector.<RigidBody>();
			for (var i:int = 0; i < 25; i++)
			{
				bodiesArr[i] = physics.createSphere(shadeMateria, 25);
				physics.getMesh(bodiesArr[i]).addEventListener(InteractiveScene3DEvent.OBJECT_PRESS, handleMousePress);
				bodiesArr[i].moveTo(new Vector3D(0, 0 + (50 * i + 50), 0));
				vplObjects.addDisplayObject3D(physics.getMesh(bodiesArr[i]));
			}
		}
		private function setupCapsuleStacking():void {
			shadeMateria = new FlatShadeMaterial(mylight,0xeeee00);
			shadeMateria.interactive = true;
			var capsuleSkin:Cylinder;
			bodiesArr = new Vector.<RigidBody>();
			for (var i:int = 0; i < 25; i++)
			{
				capsuleSkin = new Cylinder(shadeMateria, 20, 60);
				capsuleSkin.addEventListener(InteractiveScene3DEvent.OBJECT_PRESS, handleMousePress);
				scene.addChild(capsuleSkin);
				vplObjects.addDisplayObject3D(capsuleSkin);
				
				bodiesArr[i] = new JCapsule(new Pv3dMesh(capsuleSkin), 20, 60);
				bodiesArr[i].moveTo(new Vector3D(0, 0 + (40 * i + 40), 0));
				if(i%2==0){
					bodiesArr[i].setOrientation(JMatrix3D.getRotationMatrix(0, 0, 1, 90));
				}else {
					bodiesArr[i].setOrientation(JMatrix3D.getRotationMatrix(1, 0, 0, 90));
				}
				PhysicsSystem.getInstance().addBody(bodiesArr[i]);
			}
		}
		
		private function clearBodies():void {
			for each(var body:RigidBody in bodiesArr) {
				vplObjects.removeDisplayObject3D(physics.getMesh(body));
				physics.getMesh(body).material.destroy();
				physics.getMesh(body).removeEventListener(InteractiveScene3DEvent.OBJECT_PRESS, handleMousePress);
				scene.removeChild(physics.getMesh(body));
				physics.engine.removeBody(body);
			}
			bodiesArr.splice(0, bodiesArr.length);
		}
		
		private function findSkinBody(skin:DisplayObject3D):int
		{
			for (var i:String in PhysicsSystem.getInstance().bodies)
			{
				if (skin == physics.getMesh(PhysicsSystem.getInstance().bodies[i]))
				{
					return int(i);
				}
			}
			return -1;
		}
		
		private function handleMousePress(event:InteractiveScene3DEvent):void
		{
			onDraging = true;
			startMousePos = new Vector3D(mouse3D.x, mouse3D.y, mouse3D.z);
			currDragBody = PhysicsSystem.getInstance().bodies[findSkinBody(event.displayObject3D)];
			planeToDragOn = new Plane3D(new Number3D(0, 0, -1), new Number3D(0, 0, -startMousePos.z));
			
			var bodyPoint:Vector3D = startMousePos.subtract(currDragBody.currentState.position);
			dragConstraint = new JConstraintWorldPoint(currDragBody, bodyPoint, startMousePos);
		}
		
		private function handleMouseMove(event:MouseEvent):void
		{
			if (onDraging)
			{
				var ray:Number3D = camera.unproject(viewport.containerSprite.mouseX, viewport.containerSprite.mouseY);
				ray = Number3D.add(ray, new Number3D(camera.x, camera.y, camera.z));
				
				var cameraVertex3D:Vertex3D = new Vertex3D(camera.x, camera.y, camera.z);
				var rayVertex3D:Vertex3D = new Vertex3D(ray.x, ray.y, ray.z);
				var intersectPoint:Vertex3D = planeToDragOn.getIntersectionLine(cameraVertex3D, rayVertex3D);
				
				dragConstraint.worldPosition = new Vector3D(intersectPoint.x, intersectPoint.y, intersectPoint.z);
			}
		}

		private function handleMouseRelease(event:MouseEvent):void
		{
			if (onDraging)
			{
				onDraging = false;
				PhysicsSystem.getInstance().removeConstraint(dragConstraint);
				currDragBody.setActive();
			}
		}
		
		private function keyUpHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.NUMBER_1:
					clearBodies();
					setupBoxStacking();
					break;
				case Keyboard.NUMBER_2:
					clearBodies();
					setupBallStacking();
					break;
				case Keyboard.NUMBER_3:
					clearBodies();
					setupCapsuleStacking();
					break;
			}
		}
		
		protected override function onRenderTick(event:Event = null):void {
			
			physics.engine.integrate(0.1);//static timeStep
			super.onRenderTick(event);
		}
	}

}
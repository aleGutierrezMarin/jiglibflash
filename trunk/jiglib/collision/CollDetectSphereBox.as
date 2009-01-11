/*
Copyright (c) 2007 Danny Chapman 
http://www.rowlhouse.co.uk

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.
3. This notice may not be removed or altered from any source
distribution.
*/

/**
* @author Muzer(muzerly@gmail.com)
* @link http://code.google.com/p/jiglibflash
*/

package jiglib.collision {
	
	import jiglib.cof.JConfig;
	import jiglib.geometry.*;
	import jiglib.math.*;
	import jiglib.physics.RigidBody;
	import jiglib.physics.MaterialProperties;

	public class CollDetectSphereBox extends CollDetectFunctor {
		
		public function CollDetectSphereBox() {
			Name = "SphereBox";
			Type0 = "SPHERE";
			Type1 = "BOX";
		}
		
		override public function CollDetect(info:CollDetectInfo, collArr:Array):void
		{
			var tempBody:RigidBody;
			if(info.body0.Type=="BOX")
			{
				tempBody=info.body0;
				info.body0=info.body1;
				info.body1=tempBody;
			}
			
			var sphere:JSphere = info.body0 as JSphere;
			var box:JBox = info.body1 as JBox;
			
			if (!sphere.hitTestObject3D(box))
			{
				return;
			}
			
			var boxPoint:Object=new Object();
			
			var dist:Number = box.GetDistanceToPoint(boxPoint, sphere.CurrentState.Position);
			
			var depth:Number = sphere.Radius - dist;
			if (depth > -JConfig.collToll)
			{
				var dir:JNumber3D;
				var collPts:Array = new Array();
				if (dist < -JNumber3D.NUM_TINY)
				{
					dir = JNumber3D.sub(JNumber3D.sub(boxPoint.pos, sphere.CurrentState.Position), boxPoint.pos);
					dir.normalize();
				}
				else if (dist > JNumber3D.NUM_TINY)
				{
					dir = JNumber3D.sub(sphere.CurrentState.Position, boxPoint.pos);
					dir.normalize();
				}
				else
				{
					dir = JNumber3D.sub(sphere.CurrentState.Position, box.CurrentState.Position);
					dir.normalize();
				}
				
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.R0 = JNumber3D.sub(boxPoint.pos, sphere.CurrentState.Position);
				cpInfo.R1 = JNumber3D.sub(boxPoint.pos, box.CurrentState.Position);
				cpInfo.InitialPenetration = depth;
				collPts.push(cpInfo);
				
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.ObjInfo=info;
			    collInfo.DirToBody = dir;
			    collInfo.PointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.Restitution = Math.sqrt(sphere.Material.Restitution * box.Material.Restitution);
				mat.StaticFriction = Math.sqrt(sphere.Material.StaticFriction * box.Material.StaticFriction);
				mat.DynamicFriction = Math.sqrt(sphere.Material.DynamicFriction * box.Material.DynamicFriction);
				collInfo.Mat = mat;
				collArr.push(collInfo);
				
				info.body0.Collisions.push(collInfo);
			    info.body1.Collisions.push(collInfo);
			}
		}
		
	}
	
}

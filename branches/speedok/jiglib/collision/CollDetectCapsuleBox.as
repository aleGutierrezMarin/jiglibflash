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
	
	public class CollDetectCapsuleBox extends CollDetectFunctor {
		
		public function CollDetectCapsuleBox() {
			Name = "CapsuleBox";
			Type0 = "CAPSULE";
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
			
			var capsule:JCapsule = info.body0 as JCapsule;
			var box:JBox = info.body1 as JBox;
			
			if (!capsule.hitTestObject3D(box))
			{
				return;
			}
			var seg:JSegment = new JSegment(capsule.getBottomPos(), JNumber3D.multiply(capsule.CurrentState.Orientation.getCols()[1], capsule.Length));
			var radius:Number = capsule.Radius;
			
			var obj:Object = new Object();
			var distSq:Number = seg.SegmentBoxDistanceSq(obj, box);
			var arr:Array = box.CurrentState.Orientation.getCols();
			
			if (distSq < Math.pow(radius + JConfig.collToll, 2))
			{
				var segPos:JNumber3D = seg.GetPoint(Number(obj.pfLParam));
				var boxPos:JNumber3D = box.CurrentState.Position.clone();
				boxPos = JNumber3D.add(boxPos, JNumber3D.multiply(arr[0], obj.pfLParam0));
				boxPos = JNumber3D.add(boxPos, JNumber3D.multiply(arr[1], obj.pfLParam1));
				boxPos = JNumber3D.add(boxPos, JNumber3D.multiply(arr[2], obj.pfLParam2));
				
				var dist:Number = Math.sqrt(distSq);
				var depth:Number = radius - dist;
				
				var dir:JNumber3D;
				if (dist > JNumber3D.NUM_TINY)
				{
					dir = JNumber3D.sub(segPos, boxPos);
					dir.normalize();
				}
				else if (JNumber3D.sub(segPos, box.CurrentState.Position).modulo > JNumber3D.NUM_TINY)
				{
					dir = JNumber3D.sub(segPos, box.CurrentState.Position);
					dir.normalize();
				}
				else
				{
					dir = JNumber3D.UP;
					JMatrix3D.multiplyVector(JMatrix3D.rotationMatrix(0, 0, 1, 360 * Math.random()), dir);
				}
				
				var collPts:Array = new Array();
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.R0 = JNumber3D.sub(boxPos, capsule.CurrentState.Position);
				cpInfo.R1 = JNumber3D.sub(boxPos, box.CurrentState.Position);
				cpInfo.InitialPenetration = depth;
				collPts.push(cpInfo);
				
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.ObjInfo=info;
			    collInfo.DirToBody = dir;
			    collInfo.PointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.Restitution = Math.sqrt(capsule.Material.Restitution * box.Material.Restitution);
				mat.StaticFriction = Math.sqrt(capsule.Material.StaticFriction * box.Material.StaticFriction);
				mat.DynamicFriction = Math.sqrt(capsule.Material.DynamicFriction * box.Material.DynamicFriction);
				collInfo.Mat = mat;
				collArr.push(collInfo);
				
				info.body0.Collisions.push(collInfo);
			    info.body1.Collisions.push(collInfo);
			}
		}
	}
	
}

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
	import jiglib.physics.MaterialProperties;
	
	public class CollDetectCapsuleCapsule extends CollDetectFunctor {
		
		public function CollDetectCapsuleCapsule() {
			Name = "CapsuleCapsule";
			Type0 = "CAPSULE";
			Type1 = "CAPSULE";
		}
		
		override public function CollDetect(info:CollDetectInfo, collArr:Array):void
		{
			var capsule0:JCapsule = info.body0 as JCapsule;
			var capsule1:JCapsule = info.body1 as JCapsule;
			
			if (!capsule0.hitTestObject3D(capsule1))
			{
				return;
			}
			
			var seg0:JSegment = new JSegment(capsule0.getBottomPos(), JNumber3D.multiply(capsule0.CurrentState.Orientation.getCols()[1], capsule0.Length));
			var seg1:JSegment = new JSegment(capsule1.getBottomPos(), JNumber3D.multiply(capsule1.CurrentState.Orientation.getCols()[1], capsule1.Length));
			
			var radSum:Number = capsule0.Radius + capsule1.Radius;
			
			var obj:Object = new Object();
			var distSq:Number = JSegment.SegmentSegmentDistanceSq(obj, seg0, seg1);
			if (distSq < Math.pow(radSum + JConfig.collToll, 2))
			{
				var pos0:JNumber3D = seg0.GetPoint(obj.t0);
				var pos1:JNumber3D = seg1.GetPoint(obj.t1);
				
				var delta:JNumber3D = JNumber3D.sub(pos0, pos1);
				var dist:Number = Math.sqrt(distSq);
				var depth:Number = radSum - dist;
				
				if (dist > JNumber3D.NUM_TINY)
				{
					delta = JNumber3D.divide(delta, dist);
				}
				else
				{
					delta = JNumber3D.UP;
					JMatrix3D.multiplyVector(JMatrix3D.rotationMatrix(0, 0, 1, 360 * Math.random()), delta);
				}
				
				var worldPos:JNumber3D = JNumber3D.add(pos1, JNumber3D.multiply(delta, capsule1.Radius - 0.5 * depth));
				
				var collPts:Array = new Array();
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.R0 = JNumber3D.sub(worldPos, capsule0.CurrentState.Position);
				cpInfo.R1 = JNumber3D.sub(worldPos, capsule1.CurrentState.Position);
				cpInfo.InitialPenetration = depth;
				collPts.push(cpInfo);
				
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.ObjInfo=info;
			    collInfo.DirToBody = delta;
			    collInfo.PointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.Restitution = Math.sqrt(capsule0.Material.Restitution * capsule1.Material.Restitution);
				mat.StaticFriction = Math.sqrt(capsule0.Material.StaticFriction * capsule1.Material.StaticFriction);
				mat.DynamicFriction = Math.sqrt(capsule0.Material.DynamicFriction * capsule1.Material.DynamicFriction);
				collInfo.Mat = mat;
				collArr.push(collInfo);
				
				info.body0.Collisions.push(collInfo);
			    info.body1.Collisions.push(collInfo);
			}
		}
	}
	
}

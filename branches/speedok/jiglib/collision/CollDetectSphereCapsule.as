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
	
	public class CollDetectSphereCapsule extends CollDetectFunctor {
		
		public function CollDetectSphereCapsule() {
			Name = "SphereCapsule";
			Type0 = "SPHERE";
			Type1 = "CAPSULE";
		}
		
		override public function CollDetect(info:CollDetectInfo, collArr:Array):void
		{
			var tempBody:RigidBody;
			if(info.body0.Type=="CAPSULE")
			{
				tempBody=info.body0;
				info.body0=info.body1;
				info.body1=tempBody;
			}
			
			var sphere:JSphere = info.body0 as JSphere;
			var capsule:JCapsule = info.body1 as JCapsule;
			
			if (!sphere.hitTestObject3D(capsule))
			{
				return;
			}
			
			var seg:JSegment = new JSegment(capsule.getBottomPos(), JNumber3D.multiply(capsule.CurrentState.Orientation.getCols()[1], capsule.Length));
			var radSum:Number = sphere.Radius + capsule.Radius;
			
			var obj:Object = new Object();
			var distSq:Number = JSegment.PointSegmentDistanceSq(obj, sphere.CurrentState.Position, seg);
			
			if (distSq < Math.pow(radSum + JConfig.collToll, 2))
			{
				var segPos:JNumber3D = seg.GetPoint(obj.t);
				var delta:JNumber3D = JNumber3D.sub(sphere.CurrentState.Position, segPos);
				
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
				
				var worldPos:JNumber3D = JNumber3D.add(segPos, JNumber3D.multiply(delta, capsule.Radius - 0.5 * depth));
				 
				var collPts:Array = new Array();
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.R0 = JNumber3D.sub(worldPos, sphere.CurrentState.Position);
				cpInfo.R1 = JNumber3D.sub(worldPos, capsule.CurrentState.Position);
				cpInfo.InitialPenetration = depth;
				collPts.push(cpInfo);
				 
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.ObjInfo=info;
			    collInfo.DirToBody = delta;
			    collInfo.PointInfo = collPts;
				 
				var mat:MaterialProperties = new MaterialProperties();
				mat.Restitution = Math.sqrt(sphere.Material.Restitution * capsule.Material.Restitution);
				mat.StaticFriction = Math.sqrt(sphere.Material.StaticFriction * capsule.Material.StaticFriction);
				mat.DynamicFriction = Math.sqrt(sphere.Material.DynamicFriction * capsule.Material.DynamicFriction);
				collInfo.Mat = mat;
				collArr.push(collInfo);
				 
				info.body0.Collisions.push(collInfo);
			    info.body1.Collisions.push(collInfo);
			}
		}
	}
	
}

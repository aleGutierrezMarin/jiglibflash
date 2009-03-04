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
	import jiglib.geometry.JPlane;
	import jiglib.geometry.JSphere;
	import jiglib.math.JNumber3D;
	import jiglib.physics.MaterialProperties;
	import jiglib.physics.RigidBody;	

	public class CollDetectSpherePlane extends CollDetectFunctor {

		public function CollDetectSpherePlane() {
			name = "SpherePlane";
			type0 = "SPHERE";
			type1 = "PLANE";
		}

		override public function collDetect(info:CollDetectInfo, collArr:Array):void {
			var tempBody:RigidBody;
			if(info.body0.type == "PLANE") {
				tempBody = info.body0;
				info.body0 = info.body1;
				info.body1 = tempBody;
			}
			
			var sphere:JSphere = info.body0 as JSphere;
			var plane:JPlane = info.body1 as JPlane;
			
			var dist:Number = plane.pointPlaneDistance(sphere.currentState.position);
			
			if (dist > sphere.boundingSphere + JConfig.collToll) {
				return;
			}
			
			var collPts:Array = new Array();
			var cpInfo:CollPointInfo;
			var depth:Number = sphere.radius - dist;
			
			var worldPos:JNumber3D = JNumber3D.sub(sphere.currentState.position, JNumber3D.multiply(plane.normal, sphere.radius));
			cpInfo = new CollPointInfo();
			cpInfo.r0 = JNumber3D.sub(worldPos, sphere.currentState.position);
			cpInfo.r1 = JNumber3D.sub(worldPos, plane.currentState.position);
			cpInfo.initialPenetration = depth;
			collPts.push(cpInfo);
			
			var collInfo:CollisionInfo = new CollisionInfo();
			collInfo.ObjInfo = info;
			collInfo.DirToBody = plane.normal;
			collInfo.PointInfo = collPts;
			var mat:MaterialProperties = new MaterialProperties();
			mat.restitution = Math.sqrt(sphere.material.restitution * plane.material.restitution);
			mat.staticFriction = Math.sqrt(sphere.material.staticFriction * plane.material.staticFriction);
			mat.dynamicFriction = Math.sqrt(sphere.material.dynamicFriction * plane.material.dynamicFriction);
			collInfo.Mat = mat;
			collArr.push(collInfo);
			info.body0.collisions.push(collInfo);
			info.body1.collisions.push(collInfo);
		}
	}
}
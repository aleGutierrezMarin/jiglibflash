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
			this.name = "CapsuleCapsule";
			this.type0 = "CAPSULE";
			this.type1 = "CAPSULE";
		}
		
		override public function collDetect(info:CollDetectInfo, collArr:Array):void {
			var capsule0:JCapsule = info.body0 as JCapsule;
			var capsule1:JCapsule = info.body1 as JCapsule;
			
			if (!capsule0.hitTestObject3D(capsule1)) {
				return;
			}
			
			var oldSeg0:JSegment = new JSegment(capsule0.getBottomPos(capsule0.oldState), JNumber3D.multiply(capsule0.oldState.orientation.getCols()[1], capsule0.length));
			var newSeg0:JSegment = new JSegment(capsule0.getBottomPos(capsule0.currentState), JNumber3D.multiply(capsule0.currentState.orientation.getCols()[1], capsule0.length));
			var oldSeg1:JSegment = new JSegment(capsule1.getBottomPos(capsule1.oldState), JNumber3D.multiply(capsule1.oldState.orientation.getCols()[1], capsule1.length));
			var newSeg1:JSegment = new JSegment(capsule1.getBottomPos(capsule1.currentState), JNumber3D.multiply(capsule1.currentState.orientation.getCols()[1], capsule1.length));
			
			var radSum:Number = capsule0.radius + capsule1.radius;
			
			var oldObj:Object = new Object();
			var oldDistSq:Number = oldSeg0.segmentSegmentDistanceSq(oldObj, oldSeg1);
			var newObj:Object = new Object();
			var newDistSq:Number = newSeg0.segmentSegmentDistanceSq(oldObj, newSeg1);
			
			if (Math.min(oldDistSq, newDistSq) < Math.pow(radSum + JConfig.collToll, 2)) {
				var pos0:JNumber3D = oldSeg0.getPoint(oldObj.t0);
				var pos1:JNumber3D = oldSeg1.getPoint(oldObj.t1);
				
				var delta:JNumber3D = JNumber3D.sub(pos0, pos1);
				var dist:Number = Math.sqrt(oldDistSq);
				var depth:Number = radSum - dist;
				
				if (dist > JNumber3D.NUM_TINY) {
					delta = JNumber3D.divide(delta, dist);
				} else {
					delta = JNumber3D.UP;
					JMatrix3D.multiplyVector(JMatrix3D.rotationMatrix(0, 0, 1, 360 * Math.random()), delta);
				}
				
				var worldPos:JNumber3D = JNumber3D.add(pos1, JNumber3D.multiply(delta, capsule1.radius - 0.5 * depth));
				
				var collPts:Array = new Array();
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.r0 = JNumber3D.sub(worldPos, capsule0.oldState.position);
				cpInfo.r1 = JNumber3D.sub(worldPos, capsule1.oldState.position);
				cpInfo.initialPenetration = depth;
				collPts.push(cpInfo);
				
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.objInfo=info;
			    collInfo.dirToBody = delta;
			    collInfo.pointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.restitution = Math.sqrt(capsule0.material.restitution * capsule1.material.restitution);
				mat.staticFriction = Math.sqrt(capsule0.material.staticFriction * capsule1.material.staticFriction);
				mat.dynamicFriction = Math.sqrt(capsule0.material.dynamicFriction * capsule1.material.dynamicFriction);
				collInfo.mat = mat;
				collArr.push(collInfo);
				
				info.body0.collisions.push(collInfo);
			    info.body1.collisions.push(collInfo);
			}
		}
	}
	
}

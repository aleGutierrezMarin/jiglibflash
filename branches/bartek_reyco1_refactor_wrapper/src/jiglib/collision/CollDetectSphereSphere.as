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

	public class CollDetectSphereSphere extends CollDetectFunctor {

		public function CollDetectSphereSphere() {
			name = "SphereSphere";
			type0 = "SPHERE";
			type1 = "SPHERE";
		}

		override public function collDetect(info:CollDetectInfo, collArr:Array):void {
			var sphere0:JSphere = info.body0 as JSphere;
			var sphere1:JSphere = info.body1 as JSphere;
			
			var delta:JNumber3D = JNumber3D.sub(sphere0.currentState.position, sphere1.currentState.position);
			
			var dist:Number = delta.modulo;
			var radSum:Number = sphere0.radius + sphere1.radius;
			
			if (dist < radSum + JConfig.collToll) {
				var depth:Number = radSum - dist;
				delta.normalize();
				
				var worldPos:JNumber3D = JNumber3D.add(sphere1.currentState.position, JNumber3D.multiply(delta, sphere1.radius - 0.5 * depth));
				
				var collPts:Array = new Array();
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.r0 = JNumber3D.sub(worldPos, sphere0.currentState.position);
				cpInfo.r1 = JNumber3D.sub(worldPos, sphere1.currentState.position);
				cpInfo.initialPenetration = depth;
				collPts.push(cpInfo);
				
				var collInfo:CollisionInfo = new CollisionInfo();
				collInfo.objInfo = info;
				collInfo.dirToBody = delta;
				collInfo.pointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.restitution = Math.sqrt(sphere0.material.restitution * sphere1.material.restitution);
				mat.staticFriction = Math.sqrt(sphere0.material.staticFriction * sphere1.material.staticFriction);
				mat.dynamicFriction = Math.sqrt(sphere0.material.dynamicFriction * sphere1.material.dynamicFriction);
				collInfo.mat = mat;
				collArr.push(collInfo);
				
				info.body0.collisions.push(collInfo);
				info.body1.collisions.push(collInfo);
			}
		}
	}
}
